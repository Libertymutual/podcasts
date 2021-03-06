require 'spec_helper'

describe 'episodes/index.xml.builder' do
  context 'rendered with 2 episodes' do
    before(:all) { Timecop.freeze(Time.zone.now) }
    after(:all)  { Timecop.return }

    before(:each) do
      @first = create(:episode, published_on: 1.day.ago, notes: '* A list')
      create(:episode, published_on: 2.days.ago, show: @first.show)
      @first.reload
      assign(:show, @first.show)
      render
      @xml = Nokogiri::XML.parse(rendered)
    end

    it 'includes the rss and channel node' do
      expect(@xml.css('rss').length).to eq 1
      expect(@xml.css('channel').length).to eq 1
    end

    it 'includes the podcast title' do
      expect(@xml.css('channel title').first.text).to eq @first.show.title
    end

    it 'includes the podcast link' do
      link = @xml.css('channel link').first['href']
      expect(link).to eq show_episodes_url(@first.show)
    end

    it 'includes the xml url' do
      url = @xml.xpath('.//itunes:new-feed-url')
      expect(url.text).to eq show_episodes_url(@first.show, format: :xml)
    end

    it 'has an updated date of the most recently published episode' do
      expect(@xml.css('channel pubDate').first.text).
        to eq 1.day.ago.to_date.to_s(:rfc822)
    end

    it 'includes both episodes' do
      expect(@xml.css('channel item').length).to eq 2
    end

    it 'includes the guid of the episode' do
      expect(@xml.css('channel item guid').first.text).
       to eq show_episode_url(@first.show, @first)
    end

    it 'includes the full title for the episode' do
      expect(@xml.css('channel item title').first.text).to eq @first.full_title
    end

    it 'includes the date for the episode' do
      expect(@xml.css('channel item pubDate').first.text).
        to eq @first.published_on.to_s(:rfc822)
    end

    it 'has the encoded content' do
      item = @xml.css('channel item').first
      content = item.at_xpath('content:encoded').text
      expect(content).to include @first.description
      expect(content).to include BlueCloth.new(@first.notes).to_html
    end

    it 'includes an mp3 enclosure with file size and mime type' do
      item = @xml.css('channel item enclosure').first
      expect(item['url']).to eq show_episode_url(@first.show, @first, format: :mp3)
      expect(item['length']).to eq @first.file_size.to_s
      expect(item['type']).to eq 'audio/mpeg'
    end
  end

  context 'rendered with an episode with an old url' do
    before(:each) do
      @first = create(:episode, published_on: 1.day.ago, old_url: 'http://ebay.com')
      assign(:show, @first.show)
      render
      @xml = Nokogiri::XML.parse(rendered)
    end

    it 'includes the old url as the guid of the episode' do
      expect(@xml.css('channel item guid').first.text).to eq @first.old_url
    end
  end
end
