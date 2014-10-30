require 'spec_helper'
require_relative "../lib/sinatra/exstatic_assets.rb"

module Sinatra
module Exstatic

describe Asset, :time_sensitive do
  let(:asset_dir) { "app/public" }
  subject(:asset){ Asset.new filename, asset_dir }
  context "Given a file" do
    let(:fullpath) { File.join asset_dir, filename }
    before do
      File.stub(:"exists?").with(fullpath).and_return(true)
      File.stub(:mtime).with(fullpath).and_return(Time.now)
    end
    let(:filename) { "image.jpg" }
    let(:expected) { "image.jpg" }
    it { should_not be_nil }
    it { should == expected }
    its(:fullpath) { should == fullpath }
    its(:timestamp) { should == Time.now.to_i }
    its(:"is_uri?") { should be_falsy }
    its(:querystring) { should == "?ts=#{Time.now.to_i}" }
  end
  context "Given a url" do
    let(:filename) { "http://code.jquery.com/jquery-1.9.1.min.js" }
    let(:expected) { "http://code.jquery.com/jquery-1.9.1.min.js" }
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
  def uri( addr, absolute, script_tag )
    script_tag ? File.join( ENV["SCRIPT_NAME"], addr) : addr
  end
  def settings
    self
  end
  def public_folder
    "app/public"
  end
end
describe "Private methods", :time_sensitive do
  let(:o) {
    # A double, I couldn't get RSpec's to work with this
    # probably because they're not well documented
    # hint hint RSpec team
    o = FakeObject.new
  }
  let(:script_name) { "/bar" }
  let(:fullpath) { File.join asset_dir, filename }
  let(:asset_dir) { "app/public/" }
  let(:time) { Time.now.to_i }
  before do
    ENV["SCRIPT_NAME"] = script_name
    File.stub(:"exists?").with(fullpath).and_return(true)
    File.stub(:mtime).with(fullpath).and_return(time)
  end
  context "Stylesheets" do
    let(:url) { "/stylesheets/winter.css" }
    let(:filename) { "/stylesheets/winter.css" }
    let(:expected) { %Q!<link charset="utf-8" href="/bar/stylesheets/winter.css?ts=#{time}" media="screen" rel="stylesheet" />! }
    subject { o.send :sss_stylesheet_tag, url }
    it { should_not be_nil }
    it { should == expected }
  end
  context "Javascripts" do
    let(:url) { "/js/get_stuff.js" }
    let(:filename) { "/js/get_stuff.js" }
    let(:expected) { %Q!<script charset="utf-8" src="/bar/js/get_stuff.js?ts=#{time}"></script>! }
    subject { o.send :sss_javascript_tag, url }
    it { should_not be_nil }
    it { should == expected }
  end
  context "Images" do
    context "Local" do
      let(:url) { "/images/foo.png" }
      let(:filename) { "/images/foo.png" }
      let(:expected) { %Q!<img src="/bar/images/foo.png?ts=#{time}" />! }
      subject { o.send :sss_image_tag, url }
      it { should_not be_nil }
      it { should == expected }
    end
    context "Remote" do
      let(:url) { "http://example.org/images/foo.png" }
      let(:filename) { "/images/foo.png" }
      let(:expected) { %Q!<img src="#{url}" />! }
      subject { 
        o.send  :sss_image_tag,
                url
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
                url
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
                                  .stub(:exists?)
                                  .and_return(true)

    Sinatra::Exstatic::Asset.any_instance
                                  .stub(:mtime_int)
                                  .and_return(1367612251)
  end
  context "Main" do
    let(:fixture_file) { "./support/fixtures/main.txt" }
    before do
      get "/"
    end
    it_should_behave_like "Any route"
    subject { last_response.body }
    it { should == expected }
  end
  context "Sub" do
    let(:fixture_file) { "./support/fixtures/app2.txt" }
    before do
      get "/app2"
    end
    it_should_behave_like "Any route"
    subject { last_response.body }
    it { should == expected }
  end
end