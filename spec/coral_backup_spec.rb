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
end
