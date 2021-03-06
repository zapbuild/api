require 'rails_helper'

describe CommentsController, :type => :controller do
  let(:user) { User.create!({ :name => "bentron", :email => "ben@example.com", :curator => true}) }
  let(:admin_user) { User.create!({ :name => "ben", :email => "ben+admin@example.com", :admin => true }) }

  let(:article) do
    article = Article.create(doi: '123banana', title: 'hello world', owner_id: user.id, updated_at: '2006-03-05')
    article.comments.create!(owner: user, comment: "Foo", field: "fooField")
    article.comments.create!(owner: user, comment: "Bar", anonymous: true)
    article.comments.create!(owner: admin_user, comment: "Admin comment")
    article.comments.first.comments.create!(owner: user, comment: "Nested comment")
    article
  end

  before(:all) do
    WebMock.disable!
    Timecop.freeze(Time.local(1990))
  end
  after(:all) do
    WebMock.enable!
    Timecop.return
  end
  before(:each) do
    # fake :user being logged in
    controller.stub(:current_user).and_return(user)
  end

  describe "#index" do
    it "should return the list of comments" do
      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 3
    end

    it "should return nested comments" do
      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.last['comments'].count.should == 1
      results.last['comments'].first['comment'].should == "Nested comment"
    end

    it "does not return the owner name/id for anonymous comments" do
      controller.stub(:current_user).and_return(admin_user)
      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      anonymous_results = results.select{|res| res['anonymous'] == true}
      anonymous_results.count.should == 1
      res = anonymous_results[0]
      res['owner_id'].should be_nil
      res['name'].should be_nil
    end

    it "returns owner name/id for anonymous comments by the current user" do
      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      anonymous_results = results.select{|res| res['anonymous'] == true}
      anonymous_results.count.should == 1
      res = anonymous_results[0]
      res['owner_id'].should == user.id
      res['name'].should == user.name
    end

    it "should return the list of comments for a field" do
      get :index, :commentable_type => "articles", :commentable_id => article.id, :field => "fooField"
      results = JSON.parse(response.body)
      results.count.should == 1
    end

    it "should return the list of comments for the current user" do
      article # initialize these records
      get :index, :commentable_type => "users", :commentable_id => user.id
      results = JSON.parse(response.body)
      results.count.should == 3
    end
  end

  describe "#show" do
    it "should return the comment corresponding to the id" do
      comment = article.comments.first
      get :show, id: comment.id
      JSON.parse(response.body)['id'].should == comment.id
    end

    it "does not return the owner name/id for anonymous comments" do
      controller.stub(:current_user).and_return(admin_user)
      comment = article.comments.where(anonymous: true).first
      get :show, id: comment.id
      results = JSON.parse(response.body)
      results['anonymous'].should be_truthy
      results['owner_id'].should be_nil
      results['name'].should be_nil
    end

    it "returns owner name/id for anonymous comments by the current user" do
      comment = article.comments.where(anonymous: true).first
      get :show, id: comment.id
      results = JSON.parse(response.body)
      results['anonymous'].should be_truthy
      results['owner_id'].should == user.id
      results['name'].should == user.name
    end

    it "should return nested comments" do
      comment = article.comments.first
      get :show, id: comment.id
      result = JSON.parse(response.body)
      result['comments'].count.should == 1
      result['comments'].first['comment'].should == "Nested comment"
    end

    it "should return a 404 if the comment is not found" do
      get :show, id: -1
      response.status.should == 404
    end
  end

  describe "#create" do
    it "should return a 500 if comment is not provided" do
      post :create, :commentable_type => "articles", :commentable_id => article.id
      response.status.should == 500
    end

    it "should allow a comment to be created" do
      post :create, :commentable_type => "articles", :commentable_id => article.id, :comment => "my comment"
      response.status.should == 201

      comment = JSON.parse(response.body)
      comment['comment'].should == 'my comment'
      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 4
    end

    it "should set the owner when creating a comment" do
      post :create, :commentable_type => "articles", :commentable_id => article.id, :comment => "my comment"
      comment = JSON.parse(response.body)
      comment['owner_id'].should == user.id
    end

    it "should set whether the comment is anonymous when creating a comment" do
      post :create, :commentable_type => "articles", :commentable_id => article.id, :comment => "my comment"
      comment = JSON.parse(response.body)
      comment['anonymous'].should == false
    end

    it "should raise 401 if an unauthenticated user tries to post a comment" do
      controller.stub(:current_user).and_return(nil)
      post :create, :commentable_type => "articles", :commentable_id => article.id, :comment => "my comment"
      response.status.should == 401
    end
  end

  describe "#set_non_anonymous" do
    it "unanonymizes a comment owned by the current user" do
      comment = article.comments.first
      comment.update_attributes!(anonymous: true)
      comment.anonymous.should be_truthy
      post :set_non_anonymous, id: comment.id
      response.status.should == 200
      comment.reload
      comment.anonymous.should be_falsy
    end

    it "does not allow an admin to unanonymize a comment for another user" do
      controller.stub(:current_user).and_return(admin_user)
      comment = article.comments.first
      comment.update_attributes!(anonymous: true)
      comment.anonymous.should be_truthy
      post :set_non_anonymous, id: comment.id
      response.status.should == 404
      comment.reload
      comment.anonymous.should be_truthy
    end
  end

  describe "#destroy" do
    it "allows an comment created by current_user to be destroyed" do
      comment = article.comments.first
      delete :destroy, id: comment.id
      response.status.should == 204

      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 2
    end

    it "allows an comment to be destroyed by an admin" do
      controller.stub(:current_user).and_return(admin_user)
      comment = article.comments.first
      delete :destroy, id: comment.id
      response.status.should == 204

      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 2
    end

    it "does not allow current_user to destroy another user's article" do
      comment = article.comments.last
      delete :destroy, id: comment.id
      response.status.should == 401

      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 3
    end

    it "does not allow an unauthenticated user to destroy a comment" do
      controller.stub(:current_user).and_return(nil)
      comment = article.comments.first
      delete :destroy, id: comment.id
      response.status.should == 401

      get :index, :commentable_type => "articles", :commentable_id => article.id
      results = JSON.parse(response.body)
      results.count.should == 3
    end

    it "returns a 404 if comment is not found" do
      delete :destroy, id: -1
      response.status.should == 404
    end
  end
end
