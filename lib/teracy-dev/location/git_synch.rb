require 'open3'
require 'English'
require_relative '../logging'
require_relative './synch'

module TeracyDev
  module Location
    class GitWarn < StandardError
    end

    class GitSynch < Synch
      def initialize
        super

        ENV['LANGUAGE'] = 'en_US'
      end

      # location sync with git location config format:
      #
      # ```yaml
      # location:
      #   lookup_path: <the_path_to_clone>
      # //TODO(hoatle): path = lookup_path + (dir || repo_name) so we can omit the path config
      #   path: <the_git_repo_path_to_sync>
      #   git:
      #     remote:
      #       origin: <git_remote_url>
      #       <remote_name>: <git_remote_url>
      #     branch: <the_branch_to_sync> or 'master' by default
      #     tag: <the_same_as_branch>
      #     ref: <the_revision_reference_to_sync>
      #     dir: <the_dir_name_when_cloned>
      # ```
      #
      # origin remote repo is required for sync
      # git_remote_url can be ssh or https protocol. The https protocol supports authentication
      # via user:pass@host/repo.git or env var:  `HOST`_USERNAME and `HOST`_PASSWORD
      # `HOST` is normalized by converting `.` to `_` in the host,
      # eg: github.com => GITHUB_COM, 192.168.1.1 => 192_168_1_1
      #
      # TODO(hoatle): fix the host as specified above,
      # current: github.com => GITHUB, expected: GITHUB_COM
      #
      # precedence: ref > tag > branch when they co-exist within the config, 1 of them
      # must be specified
      # if none of ref, tag, branch is valid and synced, the error will be reported
      #
      # the remote repos from the config will always
      # be added/updated to the existing repo by the path
      #
      # if the path exists => we'll sync the existing repo, otherwise, we'll clone the repo
      #
      # - sync existing:
      #   + if there are uncommited changes => abort, no sync
      #   + if `master` or `develop` branch specififed => always try to fetch
      # and sync the latest (prod or dev mode)
      #   + otherwise, the ref/tag/branch must be exactly synced as specified
      # - clone:
      #   + clone the defined origin remote repo in the lookup_path dir with optional dir name
      #   + and then checkout the specified ref/tag/branch
      def sync(location_conf, sync_existing)
        start(location_conf, sync_existing)
      rescue GitWarn => e
        @logger.warn(e)
        false
      rescue
        raise
      end

      private

      # return true if sync action is carried out, otherwise, return false
      def start(location, sync_existing)
        @logger.debug("location: #{location}; sync_existing: #{sync_existing}")
        updated = false
        return updated unless Util.exist? location['git']

        lookup_path = location['lookup_path']

        path = location['path']

        git_config = location['git']

        avaiable_conf = %w[branch tag ref dir]

        if git_config.instance_of? String
          @logger.warn("Deprecated string value at location.git of location: #{location}, " \
            'please use location.git.remote.origin instead')

          git_config = {
            'remote' => {
              'origin' => git_config
            }
          }

          git_config.merge!(location.select { |k, _v| avaiable_conf.include? k })
        end

        if (avaiable_conf & location.keys).any?
          @logger.warn("#{avaiable_conf & location.keys} of location setting has been " \
            "deprecated at location: #{location}, " \
            "please use location['git'][<#{avaiable_conf.join('|')}>] instead")

          git_config.merge!(location.select { |k, _v| avaiable_conf.include? k })
        end

        git_remote = git_config['remote']

        git_remote_url = git_remote['origin'] if git_remote

        unless TeracyDev::Util.exist?(git_remote_url)
          @logger.error("git.remote.origin is required for #{path}")

          abort
        end

        branch = git_config['branch'] ||= 'master'

        tag = git_config['tag']

        ref = git_config['ref']

        dir = git_config['dir']

        if File.exist?(path)
          update_remote(path, git_remote)

          if sync_existing == true
            @logger.debug("sync existing, location: #{location}")

            Dir.chdir(path) do
              @logger.debug("Checking #{path}")

              if git_stage_has_untracked_changes?
                @logger.warn("`#{path}` has untracked changes, " \
                  "auto update is aborted!\n #{`git status`}")

                return false
              end

              current_ref = `git rev-parse --verify HEAD`.strip

              updated = if ref
                          check_ref(current_ref, ref)
                        elsif tag
                          check_tag(current_ref, tag)
                        else
                          check_branch(current_ref, branch)
                        end
            end
          end
        else
          if Vagrant::Util::Which.which('git').nil?
            @logger.error('git is not available')
            abort
          end

          unless Dir.exist?(lookup_path)
            if File.exist?(lookup_path)
              @logger.error("#{lookup_path} is a file, please delete it or use a difference name!")

              abort
            end

            Dir.mkdir(lookup_path)
          end

          Dir.chdir(lookup_path) do
            @logger.info("cd #{lookup_path} && git clone #{git_remote_url} #{dir}")

            attempt_success = attempt_to_clone_using_http_auth?(git_remote_url, dir)

            # abort the process if this fail
            exit! unless attempt_success
          end

          Dir.chdir(path) do
            @logger.info("cd #{path} && git checkout #{branch}")
            system("git checkout #{branch}")
          end

          update_remote(path, git_remote)

          updated = true
        end
        updated
      end

      # if remote_name does not exist => add
      # if remote_name exists with updated remote_url => update the remote_name
      # with the updated remote_url
      #
      # for deleting existing remote_name, it should be manually deleted by users, we do not
      # sync git remote config here, only add or update is expected
      def update_remote(path, git_remote)
        updated = false

        Dir.chdir(path) do
          @logger.debug("update git remote urls for #{path}")

          git_remote.each do |remote_name, remote_url|
            stdout, _stderr, _status = Open3.capture3("git remote get-url #{remote_name}")

            current_remote_url = stdout.strip

            next if remote_url.nil? || current_remote_url == remote_url

            `git remote remove #{remote_name}` unless current_remote_url.empty?

            `git remote add #{remote_name} #{remote_url}`

            updated = true
          end
        end

        updated
      end

      def check_ref(current_ref, ref_string)
        @logger.debug("ref detected, checking out #{ref_string}")
        updated = false
        unless current_ref.start_with? ref_string
          attempt_to_pull_using_http_auth('origin')

          `git checkout #{ref_string}`
          updated = true
        end
        updated
      end

      def check_tag(current_ref, desired_tag)
        @logger.debug("Sync with tags/#{desired_tag}")

        updated = false

        cmd = "git log #{desired_tag} -1 --pretty=%H"

        tag_ref = `#{cmd}`.strip

        unless $CHILD_STATUS.success?
          # fetch origin if tag is not present
          attempt_to_pull_using_http_auth('origin', '--tags')

          # re-check
          tag_ref = `#{cmd}`.strip

          unless $CHILD_STATUS.success?
            # tag not found
            @logger.warn("tag not found: #{desired_tag}")

            return updated
          end
        end

        @logger.debug("current_ref: #{current_ref} - tag_ref: #{tag_ref}")

        if current_ref != tag_ref
          `git checkout tags/#{desired_tag}`

          updated = true
        end

        updated
      end

      def check_branch(current_ref, desired_branch)
        @logger.debug("Sync with origin/#{desired_branch}")
        updated = false
        current_branch = `git rev-parse --abbrev-ref HEAD`.strip

        # branch master/develop are always get update
        #
        # other branch is only get update once
        if %w[master develop].include?(desired_branch)
          attempt_to_pull_using_http_auth('origin')
        # only fetch if it is valid branch and not other (tags, ref, ...)
        elsif desired_branch != current_branch && current_branch != 'HEAD'
          attempt_to_pull_using_http_auth('origin')
        end

        @logger.debug("current_branch: #{current_branch} - desired_branch: #{desired_branch}")

        quoted_branch = Regexp.quote(desired_branch).gsub('/', '\/')

        cmd_remote_ref = 'git show-ref --head | '
        cmd_remote_ref << "sed -n 's/ .*\\(refs\\/remotes\\/origin\\/#{quoted_branch}\\).*//p'"
        remote_ref = `#{cmd_remote_ref}`.strip

        # remote origin ref is not exist mean remote origin branch is not exist
        # if found no such remote branch, switch to found as tag
        return check_tag(current_ref, desired_branch) unless TeracyDev::Util.exist?(remote_ref)

        @logger.debug("current_ref: #{current_ref} - remote_ref: #{remote_ref}")

        if current_ref != remote_ref
          `git checkout #{desired_branch}`

          unless $CHILD_STATUS.success?
            # create new local branch if it is not present
            @logger.debug('No such branch! Creating one.')

            `git checkout -b #{desired_branch}`
          end

          `git reset --hard origin/#{desired_branch}`
          updated = true
        end
        updated
      end

      # return true if pull success, raise a warning otherwise
      def attempt_to_pull_using_http_auth(remote_name = 'origin', pull_options = '')
        # in most case, credentials of #{remote_name} has already been cached
        # so pull first, to see if there are any errors showing up

        pull_success, error_msg = git_fetch(remote_name, pull_options)

        return true if pull_success

        # we have errors then we will using configured credentials
        # or inform user to update, then try again

        remote_url = `git remote get-url #{remote_name}`.strip

        processed_remote_url, credential_exists,
        repo_username_key, repo_password_key = get_remote_credentials(remote_url)

        # if it is not https format
        # we will assume it is ssh format and the pull has fail
        if processed_remote_url.nil?
          fail_to_pull(remote_url)
        else
          # otherwise
          # it is https url

          # and only pull again if credentials are still exists
          if credential_exists
            @logger.debug "Attempting to pull #{remote_name}:#{remote_url} again"

            `git remote set-url #{remote_name} #{processed_remote_url}`

            pull_success, = git_fetch(remote_name)

            return true if pull_success

            # still fail then the credentials user provided are not correct
            credentials_are_present_but_fail_to_pull(remote_url,
                                                     repo_username_key,
                                                     repo_password_key)
          else
            # if credentials are not exists then inform user about it

            # we has internet but unable to connect
            if error_msg.to_s.match?('fatal: unable to access')
              fail_to_pull(remote_url)
            # we has no internet or has no credentials
            else
              internet_down_or_credential_not_found_to_pull(remote_url,
                                                            repo_username_key,
                                                            repo_password_key)
            end
          end
        end

        return false
      end

      # return true if clone success, false otherwise
      def attempt_to_clone_using_http_auth?(remote_url, dir)
        processed_remote_url, credential_exists,
        repo_username_key, repo_password_key = get_remote_credentials(remote_url)

        # if it is not https format
        # we will assume it is ssh format and use normal clone
        if processed_remote_url.nil?
          clone_success, = git_clone(remote_url, dir)

          return true if clone_success

          fail_to_access(remote_url)
        else
          # otherwise
          # it is https url
          # and wheter it has credentials or not, still clone it

          @logger.info("Attempting to using your configured credentials for #{remote_url}")

          clone_success, error_msg = git_clone(processed_remote_url, dir)

          return true if clone_success

          # we fail, so raise corresponding messages

          # we has credentials
          if credential_exists
            credentials_are_present_but_fail_to_access(remote_url,
                                                       repo_username_key,
                                                       repo_password_key)
          else
            # we has internet but unable to connect
            if error_msg.match?('fatal: unable to access')
              fail_to_access(remote_url)
            # we has no internet or has no credentials
            else
              internet_down_or_credential_not_found_to_access(remote_url,
                                                              repo_username_key,
                                                              repo_password_key)
            end
          end
        end

        return false
      end

      def get_remote_credentials(remote_url)
        regex = /(https?):\/\/(.*)/
        matches = remote_url.match(regex)

        return nil if matches.nil?

        repo_info = matches[2].split('@')

        # extract credential string
        # example: username:password@host.com/username/repo.git
        # result: host.com/username/repo.git
        repo_url = repo_info.last

        # user defined credentials: repo_info[0...-1].join('')

        # TODO(@phuonglm): I don't think get hostname is right here for example git address is
        # 192.168.1.10 then host name became 192???
        # we could just use domain name and remove all invalid character to make env var key.
        # see: https://github.com/teracyhq/dev/pull/539#discussion_r231374266
        repo_host = get_hostname(repo_url)

        # find from ENV if there are any of these credentials
        # example: GITHUB_USERNAME, GITHUB_PASSWORD
        repo_username_key = "#{repo_host}_username".upcase

        repo_password_key = "#{repo_host}_password".upcase

        credential_exists = !ENV[repo_username_key].nil? && !ENV[repo_password_key].nil?

        @logger.debug("repo_username: #{repo_username_key}=#{ENV[repo_username_key]}, " \
        "repo_password_key: #{repo_password_key}=#{ENV[repo_password_key]}")

        # only if user defined credentials are not present
        if credential_exists
          credential_str = "'#{CGI.escape ENV[repo_username_key]}':" \
          "'#{CGI.escape ENV[repo_password_key]}'"

          remote_url = "#{matches[1]}://#{credential_str}@#{repo_url}"
        end

        return remote_url, credential_exists, repo_username_key, repo_password_key
      end

      def git_fetch(remote_name, fetch_options = '')
        _stdout, stderr, status = Open3.capture3("git fetch #{remote_name} #{fetch_options}")

        # the pull is success but still has stderr return
        # if stderr is not contains 'fatal: ' message then we consider it is a success
        return true, '' if status.to_s.match('exit 0') && !stderr.to_s.match('fatal: ')

        # only display error messages when in debug
        # to prevent this error always printing out
        # if user have not used git-credential-store helper
        @logger.debug "fail to fetch (#{status}):\n#{stderr}" if Util.exist?(stderr)

        return !Util.exist?(stderr), stderr.to_s
      end

      def git_clone(remote_url, dir)
        _stdout, stderr, status = Open3.capture3("git clone #{remote_url} #{dir}")

        # the clone is success but still has stderr return
        if status.to_s.match?('exit (128|0)')
          return true, '' if Dir.exist?(dir || remote_url.split('/').last.split('.').first)
        end

        @logger.error "fail to clone (#{status}):\n#{stderr}" if Util.exist?(stderr)

        return !Util.exist?(stderr), stderr.to_s
      end

      def get_hostname(url)
        return url = url.split('.')[1] if url.start_with?('www')

        url = url.split('.')[0]

        url
      end

      def fail_to_pull(remote_url)
        raise GitWarn.new("The repo is unable to access at #{remote_url}, " \
        'please check your internet connection or check your repo info.')
      end

      def internet_down_or_credential_not_found_to_pull(remote_url,
                                                        repo_username_key,
                                                        repo_password_key)
        raise GitWarn.new("#{repo_username_key} and #{repo_password_key} " \
        "are not found to pull from #{remote_url}, " \
        'the process is aborted until those key are present, ' \
        "please run this command: \"export #{repo_username_key}='username'; " \
        "export #{repo_password_key}='password';" \
        '\" then \"vagrant status\" to see if it is working')
      end

      def credentials_are_present_but_fail_to_pull(remote_url,
                                                   repo_username_key,
                                                   repo_password_key)
        raise GitWarn.new("#{repo_username_key} and #{repo_password_key} are found " \
        "but still unable to pull from #{remote_url}, " \
        'the process is aborted until your credentials are valid, ' \
        "please run this command: \"export #{repo_username_key}='username'; " \
        "export #{repo_password_key}='password';\" then \"vagrant status\" to see " \
        'if it is working')
      end

      def fail_to_access(remote_url)
        @logger.error("The repo is unable to access at #{remote_url}, " \
        'the error has been shown above, make sure your credentials are valid, ' \
        'please follow ./docs/getting_started.rst to resolve those issues.')
      end

      def internet_down_or_credential_not_found_to_access(remote_url,
                                                          repo_username_key,
                                                          repo_password_key)
        @logger.error("#{repo_username_key} and #{repo_password_key} are not found " \
        "to access to #{remote_url}, please make sure those key are present, " \
        'please run this command: ' \
        "\"#{repo_username_key}=username #{repo_password_key}=password vagrant status\" " \
        'to see if it is working')
      end

      def credentials_are_present_but_fail_to_access(remote_url,
                                                     repo_username_key,
                                                     repo_password_key)
        @logger.error("#{repo_username_key} and #{repo_password_key} are found " \
        "but still unable to connect to #{remote_url}, " \
        'the error has been shown above, make sure your credentials are valid, ' \
        'the repo is present or your internet connection are up then try again!')
      end

      def git_stage_has_untracked_changes?
        git_status = `git status`

        regex = /nothing to commit, working .* clean/

        working_tree_are_clean = TeracyDev::Util.exist? git_status.match(regex)

        # if clean, check again if there are commits that has not been pushed
        if working_tree_are_clean

          detached_info = git_status.match(/HEAD detached (at|from) (.*)/)
          branch_info = git_status.match(/On branch (.*)/)

          if detached_info
            # if it is at ref or tag

            # has commit away from main checkout point
            has_commit_away = detached_info[1] == 'from'

            # working tree are clean when its not had commits away from its checkout point
            working_tree_are_clean = !has_commit_away
          elsif branch_info
            # if it is at a branch
            branch = branch_info[1]

            has_commit_away = false

            # all branchs except these two are consider clean
            # because commits has been saved in its branch
            if %w[develop master].include?(branch)
              have_diverged = Util.exist? git_status.match(/Your branch (.*) have diverged/)

              stdout, stderr = Open3.capture3("git cherry -v 'origin/#{branch}'")

              # is it has error we will assume it has no commit away
              @logger.debug("stderr: #{stderr}")

              has_commit_away = Util.exist? stdout.strip

              has_commit_away = have_diverged || has_commit_away
            end

            working_tree_are_clean = !has_commit_away
          end
        end
        # stage has untracked changes when working tree are not clean
        !working_tree_are_clean
      end
    end
  end
end
