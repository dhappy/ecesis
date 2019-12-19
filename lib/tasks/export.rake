namespace :export do
  desc 'Export data to external sources'

  task(dirs: :environment) do |t|
    dir = '/book/by/'
    endpoints = Datum.where('ipfs_id IS NOT NULL')
    byebug
  end
end