class BackfillPostUploadReverseIndex < ActiveRecord::Migration
  def up
    # clean the reverse index
    execute "TRUNCATE TABLE post_uploads"

    # fill the reverse index up
    Post.select([:id, :cooked]).find_each do |post|
      doc = Nokogiri::HTML::fragment(post.cooked)
      # images
      doc.search("img").each { |img| add_to_reverse_index(img['src'], post.id) }
      # thumbnails and/or attachments
      doc.search("a").each { |a| add_to_reverse_index(a['href'], post.id) }
    end
  end

  def add_to_reverse_index(url, post_id)
    if url.present? && upload_id = Discourse.store.extract_upload_id(url)
      post_upload = { upload_id: upload_id, post_id: post_id }
      PostUpload.create(post_upload) unless PostUpload.exists?(post_upload)
    end
  end

end
