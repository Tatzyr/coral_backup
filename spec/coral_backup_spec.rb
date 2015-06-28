require 'spec_helper'

describe CoralBackup do
  it "has a version number" do
    expect(CoralBackup::VERSION).not_to be nil
  end

  describe CoralBackup::FileSelector do
    let(:file_selector) { file_selector_class.new }
    let(:file_selector_class) { CoralBackup::FileSelector }

    let(:path1) { file1.path }
    let(:path2) { file2.path }
    let(:nonexistent_path) { temporary_file.path + "_blah_blah" }

    let(:file1) { Tempfile.new("file1") }
    let(:file2) { Tempfile.new("file2") }
    let(:temporary_file) { Tempfile.new("temporary_file") }

    describe "#add_file" do
      it "should add file" do
        message = "#{path1}\n"
        expect{ file_selector.add_file(path1) }.to output(message).to_stderr
        expect(file_selector.files).to contain_exactly(path1)
      end

      it "should add directory" do
        Dir.mktmpdir do |dir|
          message = dir + "\n"
          expect{ file_selector.add_file(dir) }.to output(message).to_stderr
          expect(file_selector.files).to contain_exactly(dir)
        end
      end

      it "should reject nonexistent files" do
        expect { file_selector.add_file(nonexistent_path) }.to raise_error Errno::ENOENT
      end

      it "should allow to add multiple files" do
        message = path1 + "\n" + path2 + "\n"
        expect {
          file_selector.add_file(path1)
          file_selector.add_file(path2)
        }.to output(message).to_stderr
        expect(file_selector.files).to contain_exactly(path1, path2)
      end

      it "should add absolute path file" do
        absolute_path = path1
        message = absolute_path + "\n"
        tmpdir = Pathname.new(Dir.tmpdir).realpath # expand symlinks of Dir.tmpdir
        relative_path = Pathname.new(absolute_path).relative_path_from(tmpdir).to_s
        Dir.chdir(tmpdir) do
          expect { file_selector.add_file(relative_path) }.to output(message).to_stderr
        end
        expect(file_selector.files).to contain_exactly(absolute_path)
      end
    end

    describe ".select" do
      it "should return empty array" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(file_selector_class.select).to be_empty
      end

      it "should allow to input multiple files" do
        message = "#{path1}\n#{path2}\n"
        inputs = [path1.shellescape, path2.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = file_selector_class.select }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1, path2)
      end

      it "should allow to input multiple files in one line" do
        message = "WARNING: 2 files are being added:\n#{path1}\n#{path2}\n"
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = file_selector_class.select }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1, path2)
      end

      it "should reject nonexistent files" do
        message = "#{path1}\nNo such file or directory - #{nonexistent_path}\n"
        inputs = [path1.shellescape, nonexistent_path.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = file_selector_class.select }.to output(message).to_stderr
        expect(ret).to contain_exactly(path1)
      end
    end

    describe ".single_select" do
      it "should add a file" do
        message = "#{path1}\n"
        allow(Readline).to receive(:readline) { path1 }
        ret = nil
        expect { ret = file_selector_class.single_select }.to output(message).to_stderr
        expect(ret).to eq(path1)
      end

      it "should reject multiple files in one line" do
        message = "WARNING: 2 files are being added:\n#{path1}\n#{path2}\n"
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { file_selector_class.single_select }.to output(message).to_stderr \
          .and raise_error RuntimeError
      end

      it "should be needed to input a file" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { file_selector_class.single_select }.to raise_error RuntimeError
      end

      it "should add the file when input multiple files but only one file exists" do
        message = "WARNING: 2 files are being added:\n#{path1}\nNo such file or directory - #{nonexistent_path}\n"
        inputs = [[file1.path, nonexistent_path].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        ret = nil
        expect { ret = file_selector_class.single_select }.to output(message).to_stderr
        expect(ret).to eq path1
      end
    end
  end
end
