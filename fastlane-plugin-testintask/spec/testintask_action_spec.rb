describe Fastlane::Actions::TestintaskAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The testintask plugin is working!")

      Fastlane::Actions::TestintaskAction.run(nil)
    end
  end
end
