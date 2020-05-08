require 'nokogiri'
require 'open-uri'
require 'down'
require 'csv'
require 'roo'
require 'spreadsheet'

class SearchesController < ApplicationController
  def new
  end

  def create

    page_number = [*1..10]
    page_count = 3
    # puts 'Please enter shop name'
    # shop = gets.chomp
    shop = params[:search][:shop_name]
    shop = shop.gsub(' ', '').downcase
    shop = 'goldfactoryonline' unless shop.present?
    data_file = Roo::Spreadsheet.open("data_test.xlsx")
    headers = data_file.row(1)
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'test'
    headers.each do |header|
      sheet1.row(0).push header 
    end
    # data_file.row(2).each do |value|
    #   sheet1.row(1).push value 
    # end
    # data_file.row(3).each do |value|
    #   sheet1.row(2).push value 
    # end
    dirname = params[:search][:shop_name]
    dirname = "./#{dirname}" unless dirname.present?
    FileUtils.mkdir_p(dirname) unless Dir.exists?(dirname)
    # FileUtils.mkdir_p(dirname+"ebay_images") unless Dir.exists?(dirname)

    url = "https://www.ebay.co.uk/str/#{shop}?_pgn=#{page_number.first}"
    cat_doc = data_scraper(url)
    categories = cat_doc.css('.srp-refine__category__item li')
    categories_arr = []
    cat_links = []
    categories.each do |category|
    	if cat_links.push category.css('a').attribute('href')&.value.present?
	      categories_arr.push category.text
	      cat_links.push category.css('a').attribute('href')&.value
	    end
    end
    cat_links.each_with_index do |url, url_index|
      while url != '#'
        data = data_scraper(url)
        items = data.css('.s-item__wrapper')
        urls = []
        # CSV.open('data_test.csv', 'w') do |csv|
        # csv << headers
        items.each do |item|
          url = item.css('.s-item__link').attribute('href').value
          urls.push url
          doc = data_scraper(url)
          # IMAGE DOWNLOADING 
          shop_name = doc.css('.bsi-bn').text
          product_id = doc.css('#descItemNumber').text
          product_name = doc.css('#itemTitle').text.gsub('Details about', '').strip
          product_images = doc.css('.fs_imgc li')
          img_count = 1
          product_images.first(product_images.count/2).each do |img|
            image = img.css('img').attribute('src').value
            image = image.gsub('s-l64', 's-l1600')
            temp_file = Down.download(image)
            count_append = img_count > 0 ?  "_#{img_count}" : ""
            @uniq_path = File.join(dirname, product_id+count_append+File.extname(temp_file))
            # FileUtils.mv(temp_file.path, "./#{dirname}/#{product_id}#{count_append}")
            # File.rename(temp_file.path, @uniq_path)
            FileUtils.mv(temp_file.path, @uniq_path)
            img_count = img_count + 1 
          end

          # p data_file.row(1)
          price = doc.css('#prcIsum').attribute("content").value.to_f
          web_price = price + (price * 0.10)
          # color = doc.css('.itemAttr span').last.text
          # weight = product_name.slice(0, product_name.index('ct'))
          size = string_between_markers(product_name, 'with ', ' inches')

          hashes = Hash.new
          params_table = doc.css('.itemAttr table')[1] || doc.css('.itemAttr table')
          if params_table.present?
            table_rows = params_table.css('tr').css('td')
            table_rows.each_with_index do |td, index|
              if index %2 == 0 && table_rows[index].present? && table_rows[index+1].present?

                k = table_rows[index].text.remove("\t", "\n", ":").strip
                v = table_rows[index+1].text.remove("\t", "\n", ":").strip
                hashes[k] = v
              end
            end
          end

          des_link=doc.css('iframe').attribute('src').value
          des_doc = data_scraper(des_link)
          description = des_doc.css('.template_content').text.presence || des_doc.css('#ds_div').text
          des = description
          i = des.downcase.index('gram')
          weight = i.present? ? des&.slice(i-10..i)&.match(/\d+,\d+\.\d+|\d+\.\d+|\d+/)&.to_s : ''
          p '***************************************************************'
          p product_id
          p product_name
          p hashes
          p '***************************************************************'
          product_array = []
          product_array << Time.now.to_date.to_formatted_s
          product_array << shop_name
          product_array << product_id
          product_array << product_name
          product_array << description
          product_array << "" #SEO
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << product_id
          product_array << product_id
          product_array << product_id
          product_array << "Ebay/"+product_id
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << "" #quantity
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << web_price
          product_array << price
          product_array << "#{hashes["Main Stone"]}, #{hashes["Secondary Stone"]}"
          product_array << categories_arr[url_index]
          product_array << ''
          product_array << ''
          product_array << hashes["Brand"]
          product_array << hashes["Style"]
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << '' #Pre Owned
          product_array << '' #Hallmarked
          product_array << '' #Engraving/Stampings
          product_array << hashes["Metal"]
          product_array << ''
          product_array << ''
          product_array << ''
          product_array << weight
          product_array << hashes["Gender"]
          product_array << hashes["Ring Size"]
          product_array << hashes["Width (mm)"]
          product_array << '' #Thickness (mm)
          product_array << '' #Diameter (mm)
          product_array << '' #Diameter (Soot)
          product_array << '' #Bracelet (inches)
          product_array << '' #CERTIFICATE REF
          product_array << hashes["Metal Purity"]
          product_array << hashes["Metal"]
          product_array << hashes["Clarity"]
          product_array << hashes["Pendant Shape"]
          product_array << hashes["Polish"]
          product_array << hashes["Symmetry"]
          product_array << hashes["Cut Grade"]
          product_array << hashes["Measurements"]
          product_array << hashes["Fluorescence"]



          product_array.each do |product_value|
            sheet1.row(page_count).push product_value 
          end
          # sheet1.row(page_count).push product_array
          book.write "#{dirname}.xls"
          page_count = page_count+1





            # csv << product_array
          # end


        end
        url = data.css(".ebayui-pagination__control")&.last&.attribute("href")&.value || "#"
      end
    end
    # Search.scrap_data
    # @searches = Search.all
    session[:shop_name] = params[:search][:shop_name]
    redirect_to searches_index_path
    
  end

  def index
  	@shop = session[:shop_name] || "goldfactoryonline"
  end

  def download_xls
  	@shop = session[:shop_name] || "goldfactoryonline"
  	file_path = "#{Rails.root}/#{@shop}.xls"
  	send_file(file_path, :type=>"xls", x_sendfile: true)
  end

	def download_images
		@shop = session[:shop_name] || "goldfactoryonline"
		# Dir.chdir @shop
		# binding.pry
    `zip -r "#{@shop}.zip" "#{@shop}"`
  	file_path = "#{Rails.root}/#{@shop}.zip"
  	send_file(file_path, :type=>"xls", x_sendfile: true)
	end

    private

    def data_scraper(url)
      Nokogiri::HTML(open(url))
    end
    # Use callbacks to share common setup or constraints between actions.
   
    def string_between_markers actual_string, marker1, marker2
      actual_string[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    end
end
