require "testin/version"
require 'faraday'
require 'faraday_middleware'
require 'json'
require "date"

module Testin
  class Error < StandardError; end

  def Testin.get_task
    if @dynamic_param != nil
      return @dynamic_param
    end
    @dynamic_param = Testin::Task.new($global_options)
    @dynamic_param.set_up
    @dynamic_param
  end

  def Testin.set_task options
    $global_options = options
    Testin.get_task
  end

  class Network
    def self.testin_hostname
      "http://fileupload.pro.testin.cn"
    end

    def initialize(options)
      @options = options

      @conn_options = {
          request: {
              timeout:      30,
              open_timeout: 300
          },
          #proxy: "http://127.0.0.1:8888" # for debug
      }
      @testin_client = Faraday.new(self.class.testin_hostname, @conn_options) do |c|
        c.request :url_encoded
        c.adapter :net_http
        c.response :json, :content_type => /\bjson$/
      end

    end

    def request
      path = ''
      @testin_client.post do |req|
        req.url path
        req.headers['Host'] = 'openapi.pro.testin.cn'
        req.headers['Content-Type'] = 'text/plain'
        req.body = @options[:param].to_json
      end
    end

    def validation_response response_data
      error_code = response_data['code'].to_i
      return if error_code.zero?
      raise 'validation_response error' if response_data['msg'].empty?
      raise response_data['msg']
    end
  end

  class TestinNetwork < Network

    # 登录获取token
    def get_login_token
      begin
        info = request.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error Login' if info['data']['result'].empty?
        info['data']['result']
      rescue  StandardError => e
        raise e.to_s
      end
    end

    # 获取脚本列表
    def get_script_list
      begin
        info = request.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error FetchScriptNetwork' if info['data']['list'].empty?
        info['data']['list']
      rescue StandardError => e
        #raise e.to_s
        puts(e.to_s)
      end
    end

    # 获取项目列表
    def get_project_list

      begin
        info = request.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error FetchProjectNetWork' if info['data']['list'].empty?
      end

      begin
        arr = info['data']['list'].inject([]) do |r, e|
          r << e['projectid'] if e['name'] == Testin::get_task.get_project_name
          r
        end
        raise "Project #{Testin::get_task.get_project_name} is empty" if arr.empty?
        arr[0]
      end
    end


    #获取设备列表
    def get_device_list
      begin
        info = request.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error FetchDeviceNetwork' if info['data']['list'].empty?
        info['data']['list']
      rescue StandardError => e
        raise e.to_s
      end
    end

    # 上传文件
    def upload_file(file_name)
      conn = Faraday.new(self.class.testin_hostname,@conn_options) do |c|
        c.request :multipart
        c.adapter :net_http
        c.response :json, :content_type => /\bjson$/
      end

      response = conn.post do |req|
        req.headers['Host'] = 'openapi.pro.testin.cn'
        req.headers['Transfer-Encoding'] = 'chunked'
        req.headers['Content-Type'] = 'application/octet-stream'
        req.headers['UPLOAD-JSON'] = @options[:param].to_json
        req.body = Faraday::UploadIO.new(file_name, 'application/octet-stream')
      end


      begin
        info = response.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error UPLOAD_FILE' if info['data']['result'].empty?
        info['data']['result']
      end
    end

    # 创建任务
    def creat_task
      begin
        info = request.body
        info = JSON.parse(info)
        validation_response info
        raise 'Error CREAT_TASK' if info['data']['result'].empty?
        info['data']
      end
    end

    def self.all_scripts ()

      start_page_no = 1
      array = []
      while
        #######获取脚本#######
      script_param = {
          'apikey': Testin::get_task.get_api_key,
          'mkey': 'script',
          'sid':Testin::get_task.get_sid,
          'op': 'Script.listScriptFile',
          'action': 'script',
          'timestamp': Time.now.to_i * 1000,
          'data': {
              'scriptDesc': '',
              'appId': 0,
              'startPageNo': start_page_no,
              'osType': Testin::get_task.get_os_type,
              'pageSize': 15,
              'projectId': Testin::get_task.get_project_id
          }
      }
        config = {:param => script_param}
        script = Testin::TestinNetwork.new(config)

        begin
          script_array = script.get_script_list
          break if script_array == nil || script_array.length == 0
          scripts = script_array.inject([]) do |r, e|
            r << {'scriptid': e['scriptid'],'scriptNo': e['scriptNo']} if e['taginfos'].include?'case' and e['projectId'].to_i == Testin::get_task.get_project_id and e['adapterversionname'].to_s == Testin::get_task.get_app_version
            r
          end
          if scripts.length > 0
            array = array + scripts
          end
          start_page_no += 1
        rescue StandardError => e
          raise e.to_s
        end
      end
      array.uniq
    end
  end

  class Task
    def initialize(options)
      # 1：安卓 2：IOS
      @path = options[:path]

      @devices = options[:devices]
      @project_name = options[:project_name]
      @api_key = options[:api_key]
      @app_version = options[:app_version]
      @email = options[:email]
      @pwd = options[:pwd]

      if @path.include?('ipa')
        @os_type = 2
      else
        @os_type = 1
      end
    end

    def set_up
      self.set_sid
      self.set_project_id
      puts("project_name:#{@project_name}")
      puts("sid:#{@sid}")
      puts("projectId:#{@project_id}")
      puts("devices:#{@devices}")
      puts("api_key:#{@api_key}")
      puts("email:#{@email}")
      puts("pwd:#{@pwd}")
      puts("app_version:#{@app_version}")
      puts("type:(android=1 iOS=2):#{@os_type}")
      puts('**********************init successed**********************')
    end

    def get_app_version()
      @app_version
    end

    def get_project_name()
      @project_name
    end

    def get_api_key()
      @api_key
    end

    def set_sid()
      login_param = {
          :apikey => @api_key,
          :mkey => 'usermanager',
          :op => 'Login.login',
          :data => {
              :email => @email,
              :pwd => @pwd
          },
          :action => 'user',
          :timestamp => Time.now.to_i * 1000,
      }

      config = { param: login_param }
      net = Testin::TestinNetwork.new(config)

      begin
        sid = net.get_login_token
      rescue StandardError => e
        raise e.to_s
      end
      @sid = sid
    end

    def get_sid()
      @sid
    end

    def set_project_id()
      project_param = {
          "apikey": @api_key,
          "mkey":"usermanager",
          "op":"Project.getUserProjectList",
          "data":{
              "page":1,
              "pageSize":10
          },
          "action":"user",
          "timestamp":Time.now.to_i * 1000,
          "sid": @sid
      }
      config = {:param => project_param}
      project = Testin::TestinNetwork.new(config)

      begin
        project_id = project.get_project_list
      rescue StandardError => e
        puts e.to_s
      end
      @project_id = project_id
    end

    def get_project_id()
      @project_id
    end

    def get_os_type()
      @os_type
    end

    def upload_file()
      if self.get_os_type == 2
        suffix = 'ipa'
      else
        suffix = 'apk'
      end

      ####### upload file ##########
      upload_param = {
          "apikey":Testin::get_task.get_api_key,
          "timestamp":Time.now.to_i * 1000,
          "sid":self.get_sid,
          "mkey":"fs",
          "action":"fs",
          "op":"File.upload",
          "data":
              {
                  "suffix":suffix #后缀必须写对
              }
      }
      config = {:param => upload_param}
      upload = Testin::TestinNetwork.new(config)
      upload_file_path = ''
      begin
        raise "file does not exist #{@path}" if FileTest::exist?(@path) == false
        puts '**********************start uploading**********************'
        upload_file_path = upload.upload_file(@path)
        puts '**********************end uploading**********************'
        puts 'upload_file_path:' + upload_file_path
      rescue StandardError => e
        raise e.to_s
      end
      upload_file_path
    end
    private :upload_file


    #######create task#######
    def create_task_for_normal
      upload_file_path = upload_file
      all_scripts = Testin::TestinNetwork.all_scripts
      raise 'script is empty' if all_scripts == nil || all_scripts.length == 0
      puts("all script length:#{all_scripts.length}")
      task_param =  {
          "apikey": Testin::get_task.get_api_key,
          "timestamp": Time.now.to_i * 1000,
          "sid": self.get_sid,
          "mkey": "realtest",
          "action": "app",
          "op": "Task.add",
          "data": {
              "projectid": self.get_project_id,
              "bizCode": "4001" ,# 4000 自动化兼容测试； 4001 自动化功能测试
              "taskDescr": "autotest" ,
              "appinfo": {
                  "syspfId": self.get_os_type, #1：android; 2:ios
                  "packageUrl": upload_file_path
              }, # 应用信息
              "devices": @devices,
              "scripts": all_scripts,
              "execStandard": {
                  #4000 自动化兼容测试：
                  #simple 安装+启动；
                  #monkey 安装+启动+monkey；
                  #script 安装+执行脚本
                  #4001 自动化功能测试：
                  #normal 普通执行；
                  #fast 快速执行
                  "standardType": "normal",
              } # 执行策略
          }
      }
      config = {:param => task_param}
      task = Testin::TestinNetwork.new(config)
      begin
        task.creat_task.to_s
      rescue StandardError => e
        raise e.to_s
      end
    end

    def create_task_for_fast
      upload_file_path = upload_file
      task_param =  {
          "apikey": Testin::get_task.get_api_key,
          "timestamp": Time.now.to_i * 1000,
          "sid": self.get_sid,
          "mkey": "realtest",
          "action": "app",
          "op": "Task.add",
          "data": {
              "projectid": self.get_project_id,
              "bizCode": "4001" ,# 4000 自动化兼容测试； 4001 自动化功能测试
              "taskDescr": "autotest" ,
              "appinfo": {
                  "syspfId": self.get_os_type, #1：android; 2:ios
                  "packageUrl": upload_file_path
              }, # 应用信息
              "devices": @devices,
              "scripts": Testin::TestinNetwork.all_scripts,
              "execStandard": {
                  #4000 自动化兼容测试：
                  #simple 安装+启动；
                  #monkey 安装+启动+monkey；
                  #script 安装+执行脚本
                  #4001 自动化功能测试：
                  #normal 普通执行；
                  #fast 快速执行
                  "standardType": "fast",
              } # 执行策略
          }
      }
      config = {:param => task_param}
      task = Testin::TestinNetwork.new(config)
      begin
        task.creat_task.to_s
      rescue StandardError => e
        raise e.to_s
      end
    end
  end
end
