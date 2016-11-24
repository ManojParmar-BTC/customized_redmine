class PullRequestsController < ApplicationController
  unloadable

  def index
    @project = Project.find(params[:project_id])
    @pull_requests = PullRequest.all
  end

  def github_hook
    if params[:pull_request].present?
      pull_request = PullRequest.find_or_create_by(git_id: params[:pull_request][:id], project_id: Project.find_by(identifier: params[:project_id]).id)
      pull_request.update_attributes(no: params[:pull_request][:number],
                                      git_id: params[:pull_request][:id],
                                      html_url: params[:pull_request][:html_url],
                                      difference_url: params[:pull_request][:html_url]+"/files",
                                      state: params[:pull_request][:state],
                                      title: params[:pull_request][:title])
    end

    if params[:issue].present?
      Issue.find_or_create_by!(subject: params[:issue][:title], 
                              description: params[:issue][:body], 
                              priority_id: IssuePriority.first.id, 
                              tracker_id: 1, 
                              project_id: Project.find_by(identifier: params[:project_id]).id,
                              status_id: IssueStatus.find_or_create_by(name: params[:issue][:state]).id, 
                              author_id: User.where(admin: true).first.id, 
                              start_date: Date.parse(params[:issue][:created_at]));
    end
  end

  def get_response(path)
    begin
      uri = URI(path)
      http_response = Net::HTTP.get_response(uri)
      response = JSON(http_response.body).symbolize_keys
      if response[:message].present?
        raise StandardError.new(response[:message])
      end
      response
    rescue => e
      puts "error #{e}"
    end
  end
end
