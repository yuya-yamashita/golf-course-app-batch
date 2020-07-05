require 'google_maps_service'
require 'rakuten_web_service'

module Area
  # 楽天APIで定められているエリアコード（8:茨城県,11:埼玉県,12:千葉県,13:東京都,14:神奈川県）
  CODES = %w(8 11 12 13 14)
end

module Departure
  # 基準とする出発点（今回はこの2箇所を基準となる出発地点とする）
  DEPARTURES = {
      1 => '東京駅',
      2 => '横浜駅'
  }
end

def duration_minutes(departure, destination)
  # Google Maps Platform を使用し出発地点とゴルフ場までの車での移動時間を算出している
  gmaps  = GoogleMapsService::Client.new(key: ENV['GOOGLE_MAP_API_KEY'])
  routes = gmaps.directions(
      departure,
      destination,
      region: 'jp'
  )

  # ルートが存在しない場合は nil を返す（東京の離島など）
  return unless routes.first

  # レスポンス内容から所要時間（秒）を取得している
  duration_seconds = routes.first[:legs][0][:duration][:value]
  duration_seconds / 60
end

def lambda_handler(event:, context:)
  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id  = ENV['RAKUTEN_AFID']
  end

  Area::CODES.each do |code|
    1.upto(100) do |page|
      # コース一覧を取得する(楽天APIの仕様上、一度に全てのゴルフ場を取得できないのでpageを分けて取得している) 参考(楽天APIの仕様):https://webservice.rakuten.co.jp/api/goragolfcoursesearch/
      courses = RakutenWebService::Gora::Course.search(areaCode: code, page: page)
      courses.each do |course|
        course_id   = course['golfCourseId']
        course_name = course['golfCourseName']
        # ゴルフ場以外の情報はスキップさせる（レッスン情報等）
        next if course_name.include?('レッスン')

        durations = {}
        Departure::DEPARTURES.each do |duration_id, departure|
          minutes = duration_minutes(departure, course_name)
          durations.store(duration_id, minutes) if minutes
        end
        # TODO: 取得した情報をDynamoDBに保存する
      end
      # 次のページが存在しない場合は、　break させる
      break unless courses.has_next_page?
    end
  end

  { statusCode: 200 }
end
