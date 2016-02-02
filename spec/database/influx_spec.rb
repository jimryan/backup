# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)

module Backup
describe Database::Influx do
  let(:model) { Model.new(:test_trigger, 'test label') }
  let(:db) { Database::Influx.new(model) }
  let(:s) { sequence '' }

  before do
    Database::Influx.any_instance.stubs(:utility).
      with(:influxd).returns('influxd')
  end

  it_behaves_like 'a class that includes Config::Helpers'
  it_behaves_like 'a subclass of Database::Base'

  describe '#initialize' do
    context 'when influxd_utility option is specified' do
      let(:db) do
        Database::Influx.new(model) do |db|
          db.influxd_utility = '/path/to/influxd'
        end
      end

      it 'should use the given value' do
        expect(db.influxd_utility).to eq '/path/to/influxd'
      end
    end

    context 'when influxd_utility option is not specified' do
      it 'should find influxd utility' do
        expect(db.influxd_utility).to eq 'influxd'
      end
    end
  end # describe '#initialize'

  describe '#perform!' do
    before do
      db.instance_variable_set(:@dump_path, '/dump/path')
      db.stubs(:dump_filename).returns('dump_filename')

      db.expects(:log!).in_sequence(s).with(:started)
      db.expects(:prepare!).in_sequence(s)
    end

    context 'when no compressor is configured' do
      before do
        model.expects(:compressor).returns(nil)
      end

      it 'should back up via influxd and not compress' do
        db.expects(:run).in_sequence(s).with(
          "influxd backup '/dump/path/dump_filename'"
        )

        FileUtils.expects(:rm_f).never

        db.expects(:log!).in_sequence(s).with(:finished)

        db.perform!
      end
    end

    context 'when a compressor is configured' do
      let(:compressor) { mock }

      before do
        model.expects(:compressor).twice.returns(compressor)
        compressor.expects(:compress_with).yields('gzip', '.gz')
      end

      it 'should back up via influx and compress' do
        db.expects(:run).in_sequence(s).with(
          "influxd backup '/dump/path/dump_filename'"
        )

        db.expects(:run).in_sequence(s).with(
          "gzip -c '/dump/path/dump_filename' > '/dump/path/dump_filename.gz'"
        )

        FileUtils.expects(:rm_f).in_sequence(s).with(
          '/dump/path/dump_filename'
        )

        db.expects(:log!).in_sequence(s).with(:finished)

        db.perform!
      end
    end
  end # describe '#perform!'

end
end
