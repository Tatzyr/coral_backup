require 'spec_helper'

describe CoralBackup do
  it "has a version number" do
    expect(CoralBackup::VERSION).not_to be nil
  end

  describe CoralBackup::FileSelector do
    let(:file_selector) { CoralBackup::FileSelector.new }

    describe "#add_file" do
      it "should add file" do
        Tempfile.open("foo") do |file|
          file_selector.add_file(file.path)
          expect(file_selector.files).to match_array [file.path]
        end
      end

      it "should add directory" do
        Dir.mktmpdir do |dir|
          file_selector.add_file(dir)
          expect(file_selector.files).to match_array [dir]
        end
      end

      it "should reject nonexistent files" do
        Tempfile.open("foo") do |file|
          filename = file.path + "_lorem_ipsum"
          expect { file_selector.add_file(filename) }.to raise_error Errno::ENOENT
        end
      end

      it "should be able to add multiple files" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            file_selector.add_file(file1.path)
            file_selector.add_file(file2.path)
            expect(file_selector.files).to match_array [file1.path, file2.path]
          end
        end
      end

      it "should add absolute path file" do
        tmpdir = Pathname.new(Dir.tmpdir).realpath # expand symlinks of Dir.tmpdir
        Tempfile.open("foo", tmpdir) do |file|
          absolute_path = file.path
          relative_path = Pathname.new(absolute_path).relative_path_from(tmpdir).to_s
          Dir.chdir(tmpdir) do
            file_selector.add_file(relative_path)
          end
          expect(file_selector.files).to match_array [absolute_path]
        end
      end
    end

    describe ".select" do
      it "should return empty array" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect(CoralBackup::FileSelector.select).to be_empty
      end

      it "should allow to input files" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            inputs = [file1.path.shellescape, file2.path.shellescape, nil].to_enum
            allow(Readline).to receive(:readline) { inputs.next }
            expect(CoralBackup::FileSelector.select).to match_array [file1.path, file2.path]
          end
        end
      end

      it "should allow to input multiple files" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            inputs = [[file1.path, file2.path].shelljoin, nil].to_enum
            allow(Readline).to receive(:readline) { inputs.next }
            expect(CoralBackup::FileSelector.select).to match_array [file1.path, file2.path]
          end
        end
      end

      it "should reject nonexistent files" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            inputs = [(file1.path + "_lorem_ipsum").shellescape, file2.path.shellescape, nil].to_enum
            allow(Readline).to receive(:readline) { inputs.next }
            expect(CoralBackup::FileSelector.select).to match_array [file2.path]
          end
        end
      end
    end

    describe ".single_select" do
      it "should add a file" do
        Tempfile.open("foo") do |file|
          allow(Readline).to receive(:readline) { file.path }
          expect(CoralBackup::FileSelector.single_select).to eq file.path
        end
      end

      it "should reject multiple files" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            inputs = [[file1.path, file2.path].shelljoin, nil].to_enum
            allow(Readline).to receive(:readline) { inputs.next }
            expect { CoralBackup::FileSelector.single_select }.to raise_error RuntimeError
          end
        end
      end

      it "should be needed to input a file" do
        inputs = [nil].to_enum
        allow(Readline).to receive(:readline) { inputs.next }
        expect { CoralBackup::FileSelector.single_select }.to raise_error RuntimeError
      end

      it "should add the file when input multiple files but only one file exists" do
        Tempfile.open("foo") do |file1|
          Tempfile.open("bar") do |file2|
            inputs = [[file1.path + "_lorem_ipsum", file2.path].shelljoin, nil].to_enum
            allow(Readline).to receive(:readline) { inputs.next }
            expect(CoralBackup::FileSelector.single_select).to eq file2.path
          end
        end
      end
    end
  end
end
