module Area
  # 楽天APIで定められているエリアコード（8:茨城県,11:埼玉県,12:千葉県,13:東京都,14:神奈川県）
  CODES = %w(8 11 12 13 14)
end

def lambda_handler(event:, context:)
  Area::CODES.each do |code|
    # TODO: このエリアのゴルフ場を楽天APIですべて取得する
    # TODO: 出発地点から取得したゴルフ場までの所要時間をGoogle Maps Platformで取得する
    # TODO: 取得した情報をDynamoDBに保存する
  end

  { statusCode: 200 }
end
