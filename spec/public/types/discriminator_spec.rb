require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe DataMapper::Mongo::Types::Discriminator do
  before :all do
    class Article
      include DataMapper::Mongo::Resource

      property :id,    ObjectID
      property :title, String, :required => true
      property :type,  Discriminator
    end

    class Announcement < Article; end
    class Release < Announcement; end

    Article.all.destroy!

    @article_model      = Article
    @announcement_model = Announcement
    @release_model      = Release
  end

  it 'should typecast to a Model' do
    @article_model.properties[:type].typecast('Release').should equal(@release_model)
  end

  describe 'Model#new' do
    describe 'when provided a String discriminator in the attributes' do
      before :all do
        @resource = @article_model.new(:type => 'Release')
      end

      it 'should return a Resource' do
        @resource.should be_kind_of(DataMapper::Resource)
      end

      it 'should be an descendant instance' do
        @resource.should be_instance_of(Release)
      end
    end

    describe 'when provided a Class discriminator in the attributes' do
      before :all do
        @resource = @article_model.new(:type => Release)
      end

      it 'should return a Resource' do
        @resource.should be_kind_of(DataMapper::Resource)
      end

      it 'should be an descendant instance' do
        @resource.should be_instance_of(Release)
      end
    end

    describe 'when not provided a discriminator in the attributes' do
      before :all do
        @resource = @article_model.new
      end

      it 'should return a Resource' do
        @resource.should be_kind_of(DataMapper::Resource)
      end

      it 'should be a base model instance' do
        @resource.should be_instance_of(@article_model)
      end
    end
  end

  describe 'Model#descendants' do
    it 'should set the descendants for the grandparent model' do
      @article_model.descendants.to_a.should == [ @article_model, @announcement_model, @release_model ]
    end

    it 'should set the descendants for the parent model' do
      @announcement_model.descendants.to_a.should == [ @announcement_model, @release_model ]
    end

    it 'should set the descendants for the child model' do
      @release_model.descendants.to_a.should == [ @release_model ]
    end
  end

  describe 'Model#default_scope' do
    it 'should set the default scope for the grandparent model' do
      @article_model.default_scope[:type].should equal(@article_model.descendants)
    end

    it 'should set the default scope for the parent model' do
      @announcement_model.default_scope[:type].should equal(@announcement_model.descendants)
    end

    it 'should set the default scope for the child model' do
      @release_model.default_scope[:type].should equal(@release_model.descendants)
    end
  end

  before :all do
    @announcement = @announcement_model.create(:title => 'Announcement')
  end

  it 'should persist the type' do
    @announcement.model.get(*@announcement.key).type.should equal(@announcement_model)
  end

  it 'should be retrieved as an instance of the correct class' do
    @announcement.model.get(*@announcement.key).should be_instance_of(@announcement_model)
  end

  it 'should include descendants in finders' do
    @article_model.first.should eql(@announcement)
  end

  it 'should not include ancestors' do
    @release_model.first.should be_nil
  end
end
