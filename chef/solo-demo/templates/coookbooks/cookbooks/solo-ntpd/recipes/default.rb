package "ntp" do
  action :install
end

service "ntpd" do
  case node[:platform]
  when "ubuntu"
    service_name "ntp"
  when "centos"
    service_name "ntpd"
  end
  action [ :enable, :start ]
  supports :status => true, :start => true, :stop => true, :restart => true
end

if node[:platform] == "centos"
  template "/etc/ntp/step-tickers" do
    source "step-tickers.erb"
    owner "root"
    group "root"
    mode  "600"
    notifies :restart, resources(:service => "ntpd"), :immediately
  end
end
