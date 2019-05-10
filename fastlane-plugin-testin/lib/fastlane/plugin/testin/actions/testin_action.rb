require 'fastlane/action'
require_relative '../helper/testin_helper'

module Fastlane
  module Actions
    class TestinAction < Action
      def self.run(params)
        UI.message("The testin plugin is working!")
        require 'testin'
        begin
          global_options = {
              :email => params[:email],
              :pwd => params[:pwd],
              :path => params[:path],
              :devices => params[:devices],
              :project_name => params[:project_name],
              :api_key => params[:api_key],
              :app_version => params[:app_version]
          }
          result = ::Testin.set_task(global_options).create_task_for_normal
          UI.message("Testin Plugin Successed: #{result}")
        rescue StandardError => e
          UI.user_error!("Testin Plugin Error: #{e.to_s}")
         end
      end

      def self.description
        "testin"
      end

      def self.authors
        ["rudy.li"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "testin plugin"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :email,
                                         env_name: "TESTIN_LOGIN_EMAIL",
                                         description: "email in your testin account",
                                         optional: false,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :pwd,
                                         env_name: "TESTIN_LOGIN_PWD",
                                         description: "pwd in your testin account",
                                         optional: false,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :path,
                                         env_name: "TESTIN_PATH",
                                         description: "Path to your apk/ipa file",
                                         default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                         end,
                                         conflicting_options: [:ipa],
                                         conflict_block: proc do |value|
                                           UI.user_error!("You can't use 'apk' and '#{value.key}' options in one run")
                                         end),
            FastlaneCore::ConfigItem.new(key: :devices,
                                         env_name: "TESTIN_DEVICES",
                                         description: "Set up the device for script testing",
                                         optional: false,
                                         type: Array),
            FastlaneCore::ConfigItem.new(key: :project_name,
                                         env_name: "TESTIN_PROJECT_NAME",
                                         description: "Set the testin project name for testing",
                                         optional: false,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :api_key,
                                         env_name: "TESTIN_API_KEY",
                                         description: "Testin api key",
                                         optional: false,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :app_version,
                                         env_name: "TESTIN_API_KEY",
                                         description: "Set up the version for script testing",
                                         optional: false,
                                         type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
