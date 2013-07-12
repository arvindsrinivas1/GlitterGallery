class ProjectsController < ApplicationController

  before_filter :authenticate_user!, :except => [:show, :invite]

  def new
    @user = current_user
    @project = Project.new
    @project.glimages.build
    @projects = @user.projects
    @glimages = @user.glimages
  end

  def create
    project = Project.new :name => params[:project][:name]
    project.user_id = current_user.id
    project.glimages.new :file => params[:project][:glimage][:file].original_filename, 
                         :filetype => params[:project][:glimage][:file].content_type,
                         :private => params[:project][:glimage][:private]
    if project.save
      add_the_magic project # add magicmockup.js if needed
      project_saved = true
      #write imagefile
      begin
        #write file and commit to repo
        imagefile = params[:project][:glimage][:file]
        image_commit project, imagefile
        create_thumbnail project.glimages.first
      rescue SystemCallalert
        flash[:alert] = "Unable to write image file to repo"
        project.glimages.delete
      end
      if project_saved
        redirect_to url_for(project)
      else
        redirect_to dashboard_path
      end
    else
      @project = params[:project]
      flash[:alert] = "Didn't save project!"
      redirect_to dashboard_path
    end
  end

  def invite
    @project = Project.find params[:id]
    mime_type = Mime::Type.lookup_by_extension('xml')
    content_type = mime_type.to_s unless mime_type.nil?

    @git_dir = "/#{@project.user.email}/#{@project.name}"
    render :layout => false, :content_type => content_type
  end

  def show
    @invite_uri = "sparkleshare://#{ENV['OPENSHIFT_APP_DNS'].downcase}/projects/#{params[:id]}/invite.xml"
    @project = Project.find params[:id]
    @glimage = Glimage.new
    @glimage.project_id = params[:id]
  end

end
