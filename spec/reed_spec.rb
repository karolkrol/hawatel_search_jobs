require 'spec_helper'
require 'ostruct'

xdescribe HawatelSearchJobs::Api::Reed do
  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.reed[:api] = "reed.co.uk/api"
      config.reed[:clientid] = ''
      config.reed[:page_size] = 100
    end
  end

  context 'APIs returned jobs' do
    before(:each) do
      @query_api = { :keywords => 'ruby', :location => 'London' }

      @result = HawatelSearchJobs::Api::Reed.search(
          :settings => HawatelSearchJobs.reed,
          :query => {
              :keywords => @query_api[:keywords],
              :location => @query_api[:location]
          })
    end

    it '#search' do
      validate_result(@result, @query_api)
      expect(@result.page).to be >= 0
      expect(@result.last).to be >= 0
    end

    it '#page' do
      validate_result(@result, @query_api)
      page_result = HawatelSearchJobs::Api::Reed.page({:settings => HawatelSearchJobs.reed, :query_key => @result.key, :page => 1})
      expect(page_result.key).to match(/&resultsToSkip=#{HawatelSearchJobs.reed[:page_size]}/)
      expect(page_result.page).to eq(1)
      expect(page_result.last).to be >= 0
    end

    it '#next page does not contain last page' do
      validate_result(@result, @query_api)
      page_first = HawatelSearchJobs::Api::Reed.page({:settings => HawatelSearchJobs.reed, :query_key => @result.key, :page => 1})
      page_second = HawatelSearchJobs::Api::Reed.page({:settings => HawatelSearchJobs.reed, :query_key => @result.key, :page => 2})

      page_first.jobs.each do |first_job|
        page_second.jobs.each do |second_job|
          expect(first_job.url).not_to eq(second_job.url)
        end
      end
    end

    it '#count of jobs is the same like page_size' do
      expect(@result.jobs.count).to eq(HawatelSearchJobs.reed[:page_size])
    end
  end

  context 'APIs returned empty table' do
    before(:each) do
      @query_api = { :keywords => 'job-not-found-zero-records', :location => 'London' }

      @result = HawatelSearchJobs::Api::Reed.search(
          :settings => HawatelSearchJobs.reed,
          :query => {
              :keywords => @query_api[:keywords],
              :location => @query_api[:location]
          })
    end

    it '#search' do
      validate_result(@result, @query_api)
      expect(@result.totalResults).to eq(0)
      expect(@result.page).to be_nil
      expect(@result.last).to be_nil
    end

    it '#page' do
      validate_result(@result, @query_api)
      page_result = HawatelSearchJobs::Api::Reed.page({:settings => HawatelSearchJobs.reed, :query_key => @result.key, :page => 1})
      expect(@result.totalResults).to eq(0)
      expect(@result.page).to be_nil
      expect(@result.last).to be_nil
    end

  end

  private

  def validate_result(result, query_api)
    expect(result.code).to eq(200)
    expect(result.msg).to eq('OK')
    expect(result.totalResults).to be >= 0
    expect(result.key).to match("locationName=#{query_api[:location]}")
    expect(result.key).to match("keywords=#{query_api[:keywords]}")
  end
end