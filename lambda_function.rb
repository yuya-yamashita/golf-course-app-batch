require 'rakuten_web_service'

module Area
  # 楽天APIで定められているエリアコード（8:茨城県,11:埼玉県,12:千葉県,13:東京都,14:神奈川県）
  CODES = %w(8 11 12 13 14)
end

def lambda_handler(event:, context:)
  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id  = ENV['RAKUTEN_AFID']
  end

  Area::CODES.each do |code|
    # エリアのゴルフ場を楽天APIですべて取得する
    1.upto(100) do |page|
      # コース一覧を取得する(楽天APIの仕様上、一度に全てのゴルフ場を取得できないのでpageを分けて取得している) 参考(楽天APIの仕様):https://webservice.rakuten.co.jp/api/goragolfcoursesearch/
      courses = RakutenWebService::Gora::Course.search(areaCode: code, page: page)
      courses.each do |course|
        course_id   = course['golfCourseId']
        course_name = course['golfCourseName']
        # ゴルフ場以外の情報はスキップさせる（レッスン情報等）
        next if course_name.include?('レッスン')

        # TODO: 出発地点から取得したゴルフ場までの所要時間をGoogle Maps Platformで取得する
        # TODO: 取得した情報をDynamoDBに保存する
      end
      # 次のページが存在しない場合は、　break させる
      break unless courses.has_next_page?
    end
  end

  { statusCode: 200 }
end
