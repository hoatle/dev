require_relative '../logging'
require 'open3'

module TeracyDev
  module Location
    class GitError < StandardError
    end

    class GitSynch

      def initialize
        @logger = TeracyDev::Logging.logger_for(self.class.name)
      end

      def sync(location, sync_existing)
        begin
          start(location, sync_existing)
        rescue GitError => e
          @logger.warn(e)

          false
        rescue
          raise
        end
      end

      private

      # return true if sync action is carried out, otherwise, return false
      def start(location, sync_existing)
        @logger.debug("location: #{location}; sync_existing: #{sync_existing}")
        updated = false
        return updated if ! Util.exist? location['git']

        lookup_path = location['lookup_path']

        path = location['path']

        git_config = location['git']

        avaiable_conf = ['branch', 'tag', 'ref', 'dir']

        if git_config.instance_of? String
          @logger.warn("Deprecated string value at location.git of location: #{location}, please use location.git.remote.origin instead")

          git_config = {
            "remote" => {
              "origin" => git_config
            }
          }

          git_config.merge!(location.select {|k,v| avaiable_conf.include? k })
        end

        if (avaiable_conf & location.keys).any?
          @logger.warn("#{avaiable_conf & location.keys} of location setting has been deprecated at location: #{location}, please use location['git'][<#{avaiable_conf.join('|')}>] instead")

          git_config.merge!(location.select {|k,v| avaiable_conf.include? k })
        end

        git_remote = git_config['remote']

        git_remote_url = git_remote['origin'] if git_remote

        if !Util.exist? git_remote_url
          @logger.error("git.remote.origin is required for #{path}")

          abort
        end

        branch = git_config['branch'] ||= 'master'

        tag = git_config['tag']

        ref = git_config['ref']

        dir = git_config['dir']

        if File.exist? path
          update_remote(path, git_remote)

          if sync_existing == true
            @logger.debug("sync existing, location: #{location}")

            Dir.chdir(path) do
              @logger.debug("Checking #{path}")

              if git_stage_has_untracked_changes?
                @logger.warn("`#{path}` has untracked changes, auto update is aborted!\n #{`git status`}")

                return false
              end

              current_ref = `git rev-parse --verify HEAD`.strip

              if ref
                updated = check_ref(current_ref, ref)
              elsif tag
                updated = check_tag(current_ref, tag)
              else
                updated = check_branch(current_ref, branch)
              end
            end
          end
        else
          if Vagrant::Util::Which.which('git') == nil
            @logger.error("git is not avaiable")
            abort
          end
          Dir.chdir(lookup_path) do
            @logger.info("cd #{lookup_path} && git clone #{git_remote_url} #{dir}")
            system("git clone #{git_remote_url} #{dir}")

            abort_process_if_fail_to_clone git_remote_url, dir
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
      # if remote_name exists with updated remote_url => update the remote_name with the updated remote_url
      #
      # for deleting existing remote_name, it should be manually deleted by users, we do not
      # sync git remote config here, only add or update is expected
      def update_remote(path, git_remote)
        updated = false

        Dir.chdir(path) do
          @logger.debug("update git remote urls for #{path}")

          git_remote.each do |remote_name, remote_url|
            stdout, stderr, status = Open3.capture3("git remote get-url #{remote_name}")

            current_remote_url = stdout.strip

            if !remote_url.nil? and current_remote_url != remote_url
              `git remote remove #{remote_name}` if !current_remote_url.empty?

              `git remote add #{remote_name} #{remote_url}`

              updated = true
            end

          end
        end

        updated
      end

      def check_ref(current_ref, ref_string)
        @logger.debug("ref detected, checking out #{ref_string}")
        updated = false
        if !current_ref.start_with? ref_string
          `git fetch origin`

          raise_warning_if_fail_to_fetch

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

        if !$?.success?
          # fetch origin if tag is not present
          `git fetch origin`

          raise_warning_if_fail_to_fetch

          # re-check
          tag_ref = `#{cmd}`.strip

          if !$?.success?
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
        if ['master', 'develop'].include? desired_branch
          `git fetch origin`

          raise_warning_if_fail_to_fetch
        # only fetch if it is valid branch and not other (tags, ref, ...)
        elsif desired_branch != current_branch and current_branch != 'HEAD'
          `git fetch origin`

          raise_warning_if_fail_to_fetch
        end

        @logger.debug("current_branch: #{current_branch} - desired_branch: #{desired_branch}")

        quoted_branch = Regexp.quote(desired_branch).gsub("/", '\/')

        remote_ref = `git show-ref --head | sed -n 's/ .*\\(refs\\/remotes\\/origin\\/#{quoted_branch}\\).*//p'`.strip

        # remote origin ref is not exist mean remote origin branch is not exist
        # if found no such remote branch, switch to found as tag
        return check_tag(current_ref, desired_branch) if !Util.exist? remote_ref

        @logger.debug("current_ref: #{current_ref} - remote_ref: #{remote_ref}")

        if current_ref != remote_ref
          `git checkout #{desired_branch}`

          if !$?.success?
            # create new local branch if it is not present
            @logger.debug("No such branch! Creating one.")

            `git checkout -b #{desired_branch}`
          end

          `git reset --hard origin/#{desired_branch}`
          updated = true
        end
        updated
      end

      def raise_warning_if_fail_to_fetch (remote_name = 'origin')
        if !$?.success?
          remote_url = `git remote get-url #{remote_name}`

          raise GitError.new "The repo is unable to access at #{remote_url}, please check your internet connection or check your repo info." 
        end
      end

      def abort_process_if_fail_to_clone (remote_url, dir)
        if !$?.success?

          attempt_success, error_msg = attempt_to_use_http_auth? remote_url, dir

          @logger.debug("attempt_success: #{attempt_success}")

          if !attempt_success
            processed_remote_url, credential_exists, repo_username_key, repo_password_key = get_remote_credentials remote_url

            if processed_remote_url.nil?
              @logger.error "The repo is unable to access at #{remote_url}, the error has been shown above, make sure your credentials are valid, please follow ./docs/getting_started.rst to resolve those issues."

              exit!
            end

            if credential_exists
              @logger.error "#{repo_username_key} and #{repo_password_key} are found but still unable to connect to #{remote_url}, the error has been shown above, make sure your credentials are valid, the repo is present or your internet connection are up then try again!"
            else
              # has internet but unable to connect
              if error_msg.match('fatal: unable to access')
                @logger.error "The repo is unable to access at #{remote_url}, the error has been shown above, make sure your credentials are valid, please follow ./docs/getting_started.rst to resolve those issues."

              # no internet or has no credentials
              else
                @logger.error "#{repo_username_key} and #{repo_password_key} are not found to access to #{remote_url}, please make sure those key are present, please run this command: \"#{repo_username_key}=username #{repo_password_key}=password vagrant status\" to see if it is working"
              end
            end

            exit!

          end
        end
      end

      def get_remote_credentials (remote_url)
        matches = remote_url.match(/(https?):\/\/(.*)/)

        return nil if matches.nil?

        repo_host = Util.get_hostname matches[2]

        # find from ENV if there are any of these credentials
        # example: GITHUB_USERNAME, GITHUB_PASSWORD
        repo_username_key = "#{repo_host}_username".upcase

        repo_password_key = "#{repo_host}_password".upcase

        credential_exists = !ENV[repo_username_key].nil? and !ENV[repo_password_key].nil?

        @logger.debug("repo_username: #{repo_username_key}=#{ENV[repo_username_key]}, repo_password_key: #{repo_password_key}=#{ENV[repo_password_key]}")

        if credential_exists
          remote_url = "#{matches[1]}://#{ENV[repo_username_key]}:#{ENV[repo_password_key]}@#{matches[2]}"
        end

        return remote_url, credential_exists, repo_username_key, repo_password_key
      end

      # return success value, error
      def attempt_to_use_http_auth? (remote_url, dir)
        processed_remote_url, credential_exists = get_remote_credentials remote_url

        return false, 'credential is not exists' unless credential_exists

        @logger.info("Attempting to try agian using you configurated credentials for #{remote_url}")

        stdout, stderr, status = Open3.capture3("git clone #{processed_remote_url} #{dir}")


        @logger.debug("stdout: #{stdout}, stderr: #{stderr}, status: #{status}")

        # the clone is success but still has stderr return
        if status.to_s.match('exit (128|0)')
          @logger.debug("Dir.exists?: #{Dir.exists? (dir || remote_url.split('/').last.split('.').first)}")

          if Dir.exists? (dir || remote_url.split('/').last.split('.').first)
            return true, ''
          end
        end

        return !Util.exist?(stderr), stderr.to_s
      end

      def git_stage_has_untracked_changes?
        git_status = `git status`

        working_tree_are_clean = Util.exist? git_status.match(/nothing to commit, working .* clean/)

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
            if ['develop', 'master'].include? branch
              have_diverged = Util.exist? git_status.match(/Your branch (.*) have diverged/)

              has_commit_away = Util.exist? `git cherry -v origin/#{branch}`.strip

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
