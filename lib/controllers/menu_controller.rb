class Menu
  def initialize(data = [])
    @data = data
  end

  def data
    @data.each do |key, value|
      p key
      p value
    end
  end

  def check
    false
  end

  def baddata
    @text = 'c точки зрения банальной эрудициине каждому индивиду присущи
    ksd;gk;sdkglsdkgkk;kkdsfkg;sdfgk;sk;gkgglhdhkhgkjh
    djkglkjskgjlskjfglskjglkjslgjslfdkjglskjglsgj
    sdjglksjdlfgkjsdlfgjlsdfkjglskdfj'
  end
end
