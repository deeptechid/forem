module Admin
  class ToolsController < Admin::ApplicationController
    layout "admin"

    def index; end

    def bust_cache
      flash[:success] = if params[:dead_link]
                          handle_dead_path
                          "#{params[:dead_link]} was successfully busted"
                        elsif params[:bust_user]
                          handle_user_cache
                          "User ##{params[:bust_user]} was successfully busted"
                        elsif params[:bust_article]
                          handle_article_cache
                          "Article ##{params[:bust_article]} was successfully busted"
                        end
      redirect_to "/admin/tools"
    rescue StandardError => e
      flash[:danger] = e.message
      redirect_to "/admin/tools"
    end

    private

    def handle_dead_path
      bust_link(params[:dead_link])
    end

    def handle_user_cache
      user = User.find(params[:bust_user].to_i)
      user.touch(:profile_updated_at, :last_followed_at, :last_comment_at)
      bust_link(user.path)
    end

    def handle_article_cache
      article = Article.find(params[:bust_article].to_i)
      article.touch(:last_commented_at)
      EdgeCache::BustArticle.call(article)
    end

    def bust_link(link)
      if link.starts_with?(URL.url)
        link.sub!(URL.url, "")
      end
      EdgeCache::Bust.call(link)
      EdgeCache::Bust.call("#{link}/")
      EdgeCache::Bust.call("#{link}?i=i")
      EdgeCache::Bust.call("#{link}/?i=i")
    end
  end
end
