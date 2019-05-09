require 'fastlane/action'
require_relative '../helper/testintask_helper'

module Fastlane
  module Actions
    class TestintaskAction < Action
      def self.run(params)
        UI.message("The testintask plugin is working!")
        require 'testin'
        global_options = {
            :email => 'sephora06@sephora.cn',
            :pwd => 'e10adc3949ba59abbe56e057f20f883e',
            :path => '/Users/rudy.li/Desktop/Sephora-6.3.0.4151.ipa',
            :devices => [
                {
                    "deviceid":'709173f92e1e2f9e450b657fa43c970e28495cf8'
                }
            ],
            :project_name => '丝芙兰',
            :api_key => '0cc70ef717d01b48ebfef5868a60cdd9',
            :app_version => '6.3.0'
        }
        begin
          result = Testin.set_task(global_options).create_task_for_normal
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
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "TESTINTASK_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
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
