scheduler = Rufus::Scheduler.start_new

# Delete xml directory every day at 7am
scheduler.cron("0 7 * * *") do
   FileUtils.remove_dir("/xml", true)
end 
