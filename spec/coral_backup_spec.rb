require 'spec_helper'

describe CoralBackup do
  it "has a version number" do
    expect(CoralBackup::VERSION).not_to be nil
  end

  describe CoralBackup::FileSelector do
    let(:path1) { file1.path }
    let(:path2) { file2.path }
    let(:nonexistent_path) { file1.path + "_blah_blah" }
    let(:file1) { Tempfile.new("file1") }
    let(:file2) { Tempfile.new("file2") }

    describe ".select_file" do
      it "should return a file path" do
        message = "#{path1}\n"
        allow(Readline).to receive(:readline) { path1 }
        ret = nil
        expect { ret = CoralBackup::FileSelector.select_file }.to output(message).to_stderr
        expect(ret).to eq(path1)
      end

      it "should raise error when input multiple files in single line" do
        message = "WARNING: 2 files are being added:\n#{path1}\n#{path2}\n"
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { CoralBackup::FileSelector.select_file }.to output(message).to_stderr \
          .and raise_error RuntimeError
      end

      it "should raise error when input nothing" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { CoralBackup::FileSelector.select_file }.to raise_error RuntimeError
      end

      it "should return the file path when input multiple files but only one file exists" do
        message = "WARNING: 2 files are being added:\n#{path1}\nNo such file or directory - #{nonexistent_path}\n"
        inputs = [[file1.path, nonexistent_path].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = CoralBackup::FileSelector.select_file }.to output(message).to_stderr
        expect(ret).to eq path1
      end
    end

    describe ".select_files" do
      it "should return an empty array" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(CoralBackup::FileSelector.select_files).to be_empty
      end

      it "should return file paths" do
        message = "#{path1}\n#{path2}\n"
        inputs = [path1.shellescape, path2.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = CoralBackup::FileSelector.select_files }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1, path2)
      end

      it "should allow to input multiple files in one line" do
        message = "WARNING: 2 files are being added:\n#{path1}\n#{path2}\n"
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = CoralBackup::FileSelector.select_files }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1, path2)
      end

      it "should reject nonexistent files" do
        message = "#{path1}\nNo such file or directory - #{nonexistent_path}\n"
        inputs = [path1.shellescape, nonexistent_path.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = CoralBackup::FileSelector.select_files }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1)
      end
    end
  end

  describe CoralBackup::Settings do
    SETTINGS_DATA = {
      actions: {
        "test1"=>{
          source: "/path/to/source/",
          destination: "/path/to/destination/",
          excluded_files: ["/path/to/excluded_file1", "/path/to/excluded_files2"],
          last_excuted_at: "1992-12-11 06:11:00 +0900"
        }
      }
    }

    let(:settings) {
      allow_any_instance_of(CoralBackup::Settings).to receive(:load!).and_return(Marshal.load(Marshal.dump(SETTINGS_DATA)))
      allow_any_instance_of(CoralBackup::Settings).to receive(:save!)
      CoralBackup::Settings.new
    }

    let(:empty_settings) {
      allow_any_instance_of(CoralBackup::Settings).to receive(:load!).and_return(Marshal.load(Marshal.dump(CoralBackup::Settings::INITIAL_SETTINGS)))
      allow_any_instance_of(CoralBackup::Settings).to receive(:save!)
      CoralBackup::Settings.new
    }

    describe "#action_data" do
      it "should return raw data of action" do
        expect(settings.action_data("test1")).to eq SETTINGS_DATA[:actions]["test1"]
      end

      it "should raise error when receive nonexistent action" do
        expect { settings.action_data("foofoo") }.to raise_error ArgumentError
      end
    end

    describe "#action_names" do
      it "should return array of action names" do
        expect(settings.action_names).to contain_exactly("test1")
        expect(empty_settings.action_names).to be_empty
      end
    end

    describe "#exist_action?" do
      it "should return true or false" do
        expect(settings.exist_action?("test1")).to be true
        expect(settings.exist_action?("test1foo")).to be false
      end
    end

    describe "#add" do
      it "should add the action" do
        expect { settings.add("test2", "s", "d", ["e"]) }.to change { settings.exist_action?("test2") }.from(false).to(true)
      end

      it "should raise error if given action already exists" do
        expect { settings.add("test1", "s", "d", ["e"]) }.to raise_error ArgumentError
      end
    end

    describe "#delete" do
      it "should delete the action" do
        expect { settings.delete("test1") }.to change { settings.exist_action?("test1") }.from(true).to(false)
      end

      it "should raise error if given action does not exist" do
        expect { settings.delete("test2") }.to raise_error ArgumentError
      end
    end

    describe "#update_time" do
      it "should update time" do
        old_time = "1992-12-11 06:11:00 +0900"
        new_time = Time.now.to_s
        expect { settings.update_time("test1", new_time) }.to change { settings.action_data("test1")[:last_excuted_at] }.from(old_time).to(new_time)
      end

      it "should raise error if given action does not exist" do
        expect { settings.update_time("test2") }.to raise_error ArgumentError
      end
    end
  end
end
