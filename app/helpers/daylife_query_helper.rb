module DaylifeQueryHelper
  def news_path
    "xml/#{Time.now.to_date}/news/#{Time.now.hour}/"
  end
  
  def get_daylife_document(directory, query_type)
    FileUtils.mkdir_p(directory) unless File.directory?(directory)
    
    filename = "#{directory}#{query_type.gsub(" ", "_")}.xml"
    doc = nil
    if File.exists?(filename) && File.size(filename) > 0
      file = File.open(filename)
      doc = Nokogiri::XML(file)
      file.close
    else
      daylife_object = Daylife::API.new('3718bcc1f879633b368f7491f1914786','4fa794870621ab9dee4b1e8717719c6b')
      data = daylife_object.execute('search','getRelatedArticles', {:query => "#{query_type}", :limit => 50}, ["0fNK24G6rH3Ua"])
      File.open(filename, 'wb') { |f| f.write(data) }
      doc = Nokogiri::XML(data)
    end
    return doc
  end
  
  def news_data(query_type)
    get_daylife_document(news_path, query_type)
  end
end
