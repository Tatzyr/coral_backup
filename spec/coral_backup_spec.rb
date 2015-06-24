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
        file_selector.add_file(path1)
        expect(file_selector.files).to contain_exactly(path1)
      end

      it "should add directory" do
        Dir.mktmpdir do |dir|
          file_selector.add_file(dir)
          expect(file_selector.files).to contain_exactly(dir)
        end
      end

      it "should reject nonexistent files" do
        expect { file_selector.add_file(nonexistent_path) }.to raise_error Errno::ENOENT
      end

      it "should be able to add multiple files" do
        file_selector.add_file(path1)
        file_selector.add_file(path2)
        expect(file_selector.files).to contain_exactly(path1, path2)
      end

      it "should add absolute path file" do
        tmpdir = Pathname.new(Dir.tmpdir).realpath # expand symlinks of Dir.tmpdir
        absolute_path = path1
        relative_path = Pathname.new(absolute_path).relative_path_from(tmpdir).to_s
        Dir.chdir(tmpdir) do
          file_selector.add_file(relative_path)
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

      it "should allow to input files" do
        inputs = [path1.shellescape, path2.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(file_selector_class.select).to contain_exactly(path1, path2)
      end

      it "should allow to input multiple files" do
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(file_selector_class.select).to contain_exactly(path1, path2)
      end

      it "should reject nonexistent files" do
        inputs = [path1.shellescape, nonexistent_path.shellescape, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(file_selector_class.select).to contain_exactly(path1)
      end
    end

    describe ".single_select" do
      it "should add a file" do
        allow(Readline).to receive(:readline) { path1 }
        expect(file_selector_class.single_select).to eq path1
      end

      it "should reject multiple files" do
        inputs = [[path1, path2].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { file_selector_class.single_select }.to raise_error RuntimeError
      end

      it "should be needed to input a file" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { file_selector_class.single_select }.to raise_error RuntimeError
      end

      it "should add the file when input multiple files but only one file exists" do
        inputs = [[file1.path, nonexistent_path].shelljoin, nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(file_selector_class.single_select).to eq path1
      end
    end
  end
end
