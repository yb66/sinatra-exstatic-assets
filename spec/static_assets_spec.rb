require 'spec_helper'
#require_relative "../lib/sinatra/exstatic_assets.rb"
require_relative "../lib/sinatra/exstatic_assets/formats.rb"

module Sinatra
module Exstatic

shared_context "mtime timestamp" do
  before(:each) do
    File.expects(:"exists?").with(fullpath)
                            .at_least_once
                            .returns(true)
    File.expects(:mtime).with(fullpath)
                        .returns(time)
  end
end

describe Asset, :time_sensitive do
  shared_examples "for Asset file" do
    its(:fullpath) { should == fullpath }
    its(:"is_uri?") { should be_falsy }
    it { should_not be_nil }
    it { should == expected }
  end
  let(:asset_dir) { "app/public" }
  let(:time) { Time.now }
  subject(:asset){ Asset.new filename, asset_dir, timestamp_format }
  context "Given a file" do
    let(:filename) { "image.jpg" }
    let(:expected) { "image.jpg" }
    let(:fullpath) { File.join asset_dir, filename }
    context "Using mtime as the timestamp" do
      let(:timestamp_format) { :mtime_int }
      context "" do
        include_context "mtime timestamp"
        its(:timestamp) { should == Time.now.to_i }
        its(:querystring) { should == "?ts=#{Time.now.to_i}" }
      end
      include_examples "for Asset file"
    end
    context "Using sha1 as the timestamp" do
      let(:timestamp_format) { :sha1 }
      context "" do
        before do
          digest_mock = mock()
          digest_mock.expects(:hexdigest).returns( "871cb4397c5f5f146cc5583088b12c7d0a8ddc97" )
          File.expects(:"exists?").with(fullpath).returns(true)
          Digest::SHA1.expects(:file).with(fullpath).returns(digest_mock)
        end
        its(:timestamp) { should == "871cb4397c5f5f146cc5583088b12c7d0a8ddc97" }
        its(:querystring) { should == %Q!?ts=#{"871cb4397c5f5f146cc5583088b12c7d0a8ddc97"}! }
      end
      include_examples "for Asset file"
    end
  end
  context "Given a url" do
    let(:filename) { "http://code.jquery.com/jquery-1.9.1.min.js" }
    let(:expected) { "http://code.jquery.com/jquery-1.9.1.min.js" }
    let(:timestamp_format) { :mtime_int }
    it { should_not be_nil }
    it { should == expected }
    its(:fullpath) { should be_nil }
    its(:timestamp) { should == false }
    its(:"is_uri?") { should be_truthy }
    its(:querystring) { should be_nil }
  end
end

describe Tag do
  subject { tag }
  context "Given a group of options" do
    let(:tag) {
      Tag.new "link", 
              { :type => "text/css",
                :charset => "utf-8",
                :media => "projection",
                :rel => "stylesheet",
                :href => "/bar/stylesheets/winter.css"
              }
    }
    let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css" media="projection" rel="stylesheet" type="text/css" />! }
    it { should == expected }

    context "That include closed=false" do
        let(:tag) {
          Tag.new "link", 
                  { :type => "text/css",
                    :charset => "utf-8",
                    :media => "projection",
                    :rel => "stylesheet",
                    :href => "/bar/stylesheets/winter.css",
                    :closed => false
                  }
        }
      let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css" media="projection" rel="stylesheet" type="text/css">! }
      it { should == expected }
    end
  end
end


class FakeObject
  include Sinatra::Exstatic::Private
  def initialize script_name=nil
    @script_name = script_name || public_folder
  end
  def uri( addr, absolute, script_name )
    script_name ? File.join( @script_name, addr) : addr
  end
  def settings
    self
  end
  def public_folder
    "app/public"
  end
  def xhtml
    @xhtml ||= false
  end
end

describe "Private methods", :time_sensitive do
  let(:script_name) { "/bar" }
  let(:fullpath) { File.join asset_dir, filename }
  let(:asset_dir) { "app/public/" }
  let(:time) { Time.now.to_i }
  let(:timestamp_format) { :mtime_int }
  let(:o) {
    # A double, I couldn't get RSpec's to work with this
    # probably because they're not well documented
    # hint hint RSpec team
    o = FakeObject.new script_name
  }
  
  context "Favicon" do
    let(:url) { "/favicon.ico" }
    let(:filename) { "favicon.ico" }
    let(:expected) { %Q!<link href="/bar/favicon.ico" rel="icon" />! }
    subject {
      o.send :sss_favicon_tag, url, {asset_dir: asset_dir}, {}
    }
    it { should == expected }
  end
  context "Accessing the file system" do
    include_context "mtime timestamp" do
    end
    context "Stylesheets" do
      before do
        ENV["SCRIPT_NAME"] = script_name
      end
      let(:url) { "/stylesheets/winter.css" }
      let(:filename) { "/stylesheets/winter.css" }
      context "Given a filename" do
        context "But no options" do
          let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css?ts=#{time}" media="screen" rel="stylesheet" />! }
          subject { o.send :sss_stylesheet_tag, url, {asset_dir: asset_dir, timestamp_format: timestamp_format}, {} }
          it { should == expected }
        end
        context "with options" do
          context "media=print" do
            let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css?ts=#{time}" media="print" rel="stylesheet" />! }
            subject { o.send :sss_stylesheet_tag, url, {asset_dir: asset_dir,media: "print", timestamp_format: timestamp_format}, {} }
            it { should == expected }       
          end
        end
      end
    end
    context "Javascripts" do
    let(:url) { "/js/get_stuff.js" }
    let(:filename) { "/js/get_stuff.js" }
    let(:expected) { %Q!<script charset="utf-8" src="/bar/js/get_stuff.js?ts=#{time}"></script>! }
    subject { o.send :sss_javascript_tag, url, {asset_dir: asset_dir, timestamp_format: timestamp_format}, {} }
    it { should_not be_nil }
    it { should == expected }
  end
  end
  context "Images" do
    context "Local" do
      let(:url) { "/images/foo.png" }
      let(:filename) { "/images/foo.png" }
      let(:expected) { %Q!<img src="/bar/images/foo.png?ts=#{time}" />! }
      subject { o.send :sss_image_tag, url, {asset_dir: asset_dir, timestamp_format: :mtime_int}, {} }
      
      context "Using mtime as the timestamp" do
        include_context "mtime timestamp"
        it { should_not be_nil }
        it { should == expected }
      end
    end
    context "Remote" do
      let(:url) { "http://example.org/images/foo.png" }
      let(:filename) { "/images/foo.png" }
      let(:expected) { %Q!<img src="#{url}" />! }
      subject { 
        o.send  :sss_image_tag,
                url, {asset_dir: asset_dir}, {}
      }
      it { should_not be_nil }
      it { should == expected }
    end
    context "Remote and secure" do
      let(:url) { "https://example.org/images/foo.png" }
      let(:filename) { "/images/foo.png" }
      let(:expected) { %Q!<img src="#{url}" />! }
      subject { 
        o.send  :sss_image_tag,
                url, {asset_dir: asset_dir}, {}
      }
      it { should_not be_nil }
      it { should == expected }
    end
  end
end

end # Exstatic
end # Sinatra

describe "Using them with a Sinatra app", :time_sensitive do
  include_context "All routes"
  let(:expected) { File.read File.expand_path(fixture_file, File.dirname(__FILE__)) }
  before do
    Sinatra::Exstatic::Asset.any_instance
                                  .expects(:exists?)
                                  .at_least_once
                                  .returns(true)

    Sinatra::Exstatic::Asset.any_instance
                                  .expects(:mtime_int)
                                  .at_least_once
                                  .returns(1367612251)
  end
  context "Main" do
    context "/" do
      let(:fixture_file) { "./support/fixtures/main.html" }
      before do
        get "/"
      end
      it_should_behave_like "Any route"
      subject { last_response.body }
      it { should == expected }
    end
    context "/deeper" do
      let(:fixture_file) { "./support/fixtures/app-deeper.html" }
      before do
        get "/deeper"
      end
      it_should_behave_like "Any route"
      subject { last_response.body }
      it { should == expected }
    end
  end
  context "Sub" do
    context "/app2/" do
      let(:fixture_file) { "./support/fixtures/app2.html" }
      before do
        get "/app2"
      end
      it_should_behave_like "Any route"
      subject { last_response.body }
      it { should == expected }
    end
    context "/app2/deeper" do
      let(:fixture_file) { "./support/fixtures/app2-deeper.html" }
      before do
        get "/app2/deeper"
      end
      it_should_behave_like "Any route"
      subject { last_response.body }
      it { should == expected }
    end
    context "/app2/deeper" do
      let(:fixture_file) { "./support/fixtures/app2-deeper.html" }
      before do
        get "/app2/deeper/and-deeper"
      end
      it_should_behave_like "Any route"
      subject { last_response.body }
      it { should == expected }
    end
  end
end