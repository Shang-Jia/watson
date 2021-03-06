class EntriesController < ApplicationController
  include UploadHelper
  skip_before_filter :require_login, only: [:landing]
  
  def landing

  end

  def index
    @entries = Entry.all
    respond_to do |format|
      format.html 
      # format.json { 
      #   render json: EntryDatatable.new(view_context)
      # }
    end
  end

  def show
    @entry = Entry.find(params[:id])
    unless @entry.insights.nil?
      @big5 = @entry.insights["tree"]["children"][0]
      @needs = @entry.insights["tree"]["children"][1]
      @values = @entry.insights["tree"]["children"][2]
    end
  end

  def new
    @entry = Entry.new
  end

  def analyse
    @entry = Entry.find(params[:id])
    profile_api_url = "#{Figaro.env.bluemix_url}/v2/profile"
    client = RestClient::Resource.new(profile_api_url, Figaro.env.bluemix_username, Figaro.env.bluemix_password)
    insights = client.post @entry.transcript, :content_type => "text/plain;charset=utf-8"
    if @entry.update_attribute(:insights, JSON.load(insights.body))
      redirect_to entry_path(@entry.id), :flash => { :success => "Watson analytics updated sucessfully." }
    end
  end

  def multi_select
    if !!params[:entries_ids]
      @multi_select = Entry.find(params[:entries_ids])
    else
      flash.now[:error] = "You didn't select any transcripts."
      render :index
    end
  end

  def analyse_all
    @multi_entry = Entry.find(params[:entries_ids])
    @multi_entry.each do |entry|
      profile_api_url = "#{Figaro.env.bluemix_url}/v2/profile"
      client = RestClient::Resource.new(profile_api_url, Figaro.env.bluemix_username, Figaro.env.bluemix_password)
      insights = client.post entry.transcript, :content_type => "text/plain;charset=utf-8"
      entry.update_attribute(:insights, JSON.load(insights.body))
    end
    redirect_to entries_path, :flash => { :success => "Watson analytics updated sucessfully on multiple selections." }
  end

  def edit
    @entry = Entry.find(params[:id])
  end

  def update
    @entry = Entry.find(params[:id])
    if @entry.update_attributes(entry_params)
      redirect_to entries_path, :flash => { :success => "Record for #{@entry.company_name} updated Sucessfully." }
    else
      @entry.errors.full_messages.each do |msg|
        flash.now[:error] = msg
      end
      render :edit 
    end
  end

  def destroy 
    if params[:id] == "delete_all"
      Entry.delete_all
    else
      @entry = Entry.find(params[:id])
      @entry.delete
    end
    redirect_to entries_path
  end

  def upload
    #helper method defined in upload_helper.rb
    process_upload(params[:file])
  end

  def linkedin
    redirect_to "https://www.linkedin.com/pub/dir/?first=" + params[:firstname] + "&last="\
    + params[:lastname] + "&search=Search"
  end

end



private
# def analyse(input)
#   profile_api_url = "#{Figaro.env.bluemix_url}/v2/profile"
#   client = RestClient::Resource.new(profile_api_url, Figaro.env.bluemix_username, Figaro.env.bluemix_password)
#   insights = client.post input, :content_type => "text/plain;charset=utf-8"
#   @watson_says = JSON.load(insights.body)
# end

def entry_params
  params.require(:entry).permit(:company_name, :ticker, :event_name, :date, :speaker_name, :speaker_title, :wcount, :transcript, :insights)
end







