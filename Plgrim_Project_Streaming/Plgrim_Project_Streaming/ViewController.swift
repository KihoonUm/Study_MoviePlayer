//
//  ViewController.swift
//  Plgrim_Project_Streaming
//
//  Created by Bard on 2021/09/03.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var videoPlayer: UIView!
    @IBOutlet var videoButton: UIView!
    @IBOutlet var videoCurrent: UIView!
    @IBOutlet var videoVolume: UIView!
    
    @IBOutlet var btn_play: UIButton!
    @IBOutlet var lbl_CurrentTime: UILabel!
    @IBOutlet var lbl_EndTime: UILabel!
    @IBOutlet var sl_VideoTime: UISlider!
    @IBOutlet var sl_VideoVolume: UISlider!
    @IBOutlet var lbl_AddTime: UILabel!
    @IBOutlet var button_Nextvideo: UIButton!
    @IBOutlet var button_beforeViedeo: UIButton!
    
    let MAX_VOLUME : Float = 10.0
    var player : AVPlayer! // 영상을 재생하기 위한 클래스
    var player_Layer : AVPlayerLayer! // 재생한 영상을 화면에 나타내기 위한 클래스 -> 오직 화면에 나타내기만함
    var isPlay = true
    var btn_img : UIImage?
    var cnt = 0
    var video_Timer : Timer! // 비디오시간 타이머
    var lbl_Timer : Timer! // 탑바텀 라벨 타이머
    var add_Time : Float64 = 0.0


    let urlName : [String] = ["https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8", "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8", "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"]
    var pageNum : Int = 0
    var url : URL!
    
    let timePlayerSelector : Selector = #selector(ViewController.updatePlayTime) // 플레이어 시간 셀렉터
    let timeTouchSelector : Selector = #selector(ViewController.updateTouchTime) // 탑바텀 라벨 셀렉터
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        sl_VideoVolume.minimumValue = 0.0
        sl_VideoVolume.maximumValue = MAX_VOLUME
        sl_VideoVolume.value = 1.0
        url = URL(string: urlName[pageNum])
        player = AVPlayer(url: url) // 플레이어생성
        
        //플레이어 시간에 대한 옵저버함수를 붙임 -> (duration)재생시간이 변경될 때마다 실행됨
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        player_Layer = AVPlayerLayer(player: player) // 출력클래스에 비디오 장착
        player_Layer.videoGravity = .resize // 레이어 안에서 비디오를 나타내는 방법 -> 크기조정 종횡비값
        player.volume = sl_VideoVolume.value
        sl_VideoTime.minimumValue = 0.0
        videoPlayer.layer.addSublayer(player_Layer) // 영상UIView에 플레이어 레이어를 추가함 -> 플레이어 장착
        
        
        video_Timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true) // 비디오 시간 0.1초마다 재생
    }
    
    override func viewDidAppear(_ animated: Bool) { // 뷰가완전히 보이고난 후 실행되는 함수 -> 뷰가 완성되고 나서 영상시작
        player.play()
        // 옵저버함수 추가 -> 영상이 끝나면 videoDidEnd함수 실행
        if pageNum == urlName.count - 1 {
            button_Nextvideo.isEnabled = false
        } else if pageNum == 0 {
            button_beforeViedeo.isEnabled = false
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name:
        NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil) // 알림이름 -> 비디오끝나는알림 재생이 종료되면 알림
        
    }
    override func viewDidLayoutSubviews() { // 서브뷰의 레이아웃이 변경된 후 호출되는 함수 -> 서브뷰의 레이아웃을 변경 후 추가 작업의 시점
        player_Layer.frame = videoPlayer.bounds // SuperView의 좌표시스템을 기준으로 뷰의 크기와 위치를 나타냄 : Frame = 자신만의 좌표시스템 에서 뷰의 크기와 위치를 나타냄 : Bounds
        // player_Layer의 SuperView의 크기를 videoPlayer의 크기로 맞춤 -> 영상을 회전하여 뷰의 사이즈가 변경될때 사이즈를 맞추기 위함
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // 터치시 비디오상태라벨등장
       top_bottom_LabelOn()
    }
    
    func top_bottom_LabelOn() { // 숨겨왔던 라벨 뷰 등장 -> 5초 카운트 후 사라짐
        lbl_Timer?.invalidate()
        lbl_Timer = nil
        videoButton.isHidden = false
        videoCurrent.isHidden = false
        videoVolume.isHidden = false
        button_Nextvideo.isHidden = false
        button_beforeViedeo.isHidden = false
        lbl_Timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: timeTouchSelector, userInfo: nil, repeats: true)
    }

    func getTimeString(_ totalTime : CMTime) -> String { // 시간초를 정해진 문자열로 반환하는 함수
        let time = CMTimeGetSeconds(totalTime)
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d : %02d", min, sec)
        return strTime
    }
    
    @objc func videoDidEnd(notification: NSNotification) { // 영상이 끝나면 재생될 함수
       print("video ended")
        isPlay = !isPlay
        btn_img = UIImage(systemName: "play.fill")
        btn_play.setImage(btn_img, for: .normal)
        let time = CMTime(value: Int64(600), timescale: 600)
        player.seek(to: time) // seek -> 현재 재생시간을 time으로 설정
        top_bottom_LabelOn()
        add_Time = 0
    }
    
    deinit { // 메모리관리를 위하여 감시자 제거 -> 알람 메모리해제
        print("메모리해제")
       NotificationCenter.default.removeObserver(self)
    }

    @IBAction func panGesture(_ recognizer : UIPanGestureRecognizer){
        let velocity = recognizer.velocity(in: self.view)
        if velocity.x.magnitude > velocity.y.magnitude{ // 좌우
            velocity.x < 0 ? barckward_Video(1.0) : forward_Video(1.0)
        } else { // 상하
            velocity.y < 0 ? volume_Controll(0.1) : volume_Controll(-0.1)
        }
    }
    
    func volume_Controll(_ value : Float) { // 음량관리 함수
        sl_VideoVolume.value += value
        player.volume = sl_VideoVolume.value
        lbl_AddTime.text = "볼륩값 : \(Int(player.volume))"
        lbl_AddTime.isHidden = false
    }
    
    @objc func updatePlayTime(){ // 최근시간 라벨과, 비디오시간 슬라이더 값 바꿈
        lbl_CurrentTime.text = getTimeString(player.currentTime())
        sl_VideoTime.value = Float(player.currentTime().seconds)
    }

    @objc func updateTouchTime(){ // 5초간 반복되어 실행될 함수 cnt
        if cnt > 5 {
            cnt = 0
            videoButton.isHidden = true
            videoCurrent.isHidden = true
            videoVolume.isHidden = true
            lbl_AddTime.isHidden = true
            button_Nextvideo.isHidden = true
            button_beforeViedeo.isHidden = true
            add_Time = 0
            print("선택창꺼짐")
            lbl_Timer.invalidate()
            lbl_Timer = nil
        }
        cnt += 1
    }
    
    @IBAction func btn_playAction(_ sender: UIButton) {
        if isPlay{
            btn_img = UIImage(systemName: "play.fill")
            sender.setImage(btn_img, for: .normal)
            player.pause()
        } else{
            btn_img = UIImage(systemName: "pause.fill")
            sender.setImage(btn_img, for: .normal)
            player.play()
        }
        isPlay = !isPlay
    }
    
    @IBAction func btn_backwardAction(_ sender: UIButton) { // 뒤로가기버튼
        barckward_Video(5.0)
    }
    @IBAction func btn_forwardAction(_ sender: UIButton) { // 앞으로가기버튼
        forward_Video(5.0)
    }
    
    func barckward_Video(_ back_num : Float64) { // 시간을 받아서 뒤로 감는 함수
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - back_num
        if add_Time > 0 { add_Time = 0 }
        add_Time -= back_num
        lbl_AddTime.text = "\(Int64(add_Time))"
        lbl_AddTime.isHidden = false
        
        if newTime < 0 {
            newTime = 0
            add_Time += back_num
        }
        let time = CMTime(value: Int64(newTime*600), timescale: 600)
        player.seek(to: time)
    }
    
    func forward_Video(_ forward_num : Float64) { // 시간을 받아서 앞으로 감는 함수
        guard let duration = player.currentItem?.duration else {
            return
        }
        let currenTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currenTime + forward_num
        if add_Time < 0 { add_Time = 0 }
        add_Time += forward_num
        lbl_AddTime.text = "+\(Int64(add_Time))"
      
        lbl_AddTime.isHidden = false
        if newTime < CMTimeGetSeconds(duration) - forward_num{
            let time = CMTime(value: Int64(newTime*600), timescale: 600)
            player.seek(to: time)
        }
    }
    
    @IBAction func btn_SpeedChange(_ sender: UIButton) {
        if player.rate == 0.5 {
            speed_Change(1.0)
            sender.setTitle("1.0배속", for : .normal)
        }else if player.rate == 2.0 {
            speed_Change(0.5)
            sender.setTitle("0.5배속", for : .normal)
        }else if player.rate == 1.0 {
            speed_Change(2.0)
            sender.setTitle("2.0배속", for : .normal)
        }
    }
    
    func speed_Change(_ rate : Float)  {
        cnt = 0
        lbl_AddTime.isHidden = true
        add_Time = 0
        player.rate = rate
        if !isPlay {
        btn_img = UIImage(systemName: "pause.fill")
        btn_play.setImage(btn_img, for: .normal)
            isPlay = !isPlay
        }
    }
    
    @IBAction func sl_VideoTime_Change(_ sender: UISlider) {
        player.seek(to: CMTime(value: Int64(sender.value*600), timescale: 600))
        add_Time = 0
        lbl_AddTime.isHidden = true
    }
    
    @IBAction func sl_VideoVolume_Change(_ sender: UISlider) {
        player.volume = sender.value
        add_Time = 0
        cnt = 0
        lbl_AddTime.isHidden = false
        lbl_AddTime.text = "볼륩값 : " + String(Int(sender.value))
    }
    
    
    @IBAction func btn_BeforeVideo(_ sender: UIButton) {
       pageChange(false)
        print("이전페이지")
    }
    
    @IBAction func btn_NextVideo(_ sender: UIButton) {
       pageChange(true)
        print("다음페이지")
    }
    func pageChange(_ next : Bool) {
        dismiss(animated: false, completion: nil)
         button_Nextvideo.isEnabled = true
         button_beforeViedeo.isEnabled = true
        if next {
            if pageNum < urlName.count-1 {
                pageNum += 1
                viewDidLoad()
                viewDidAppear(true)
            }
        }else
        {
            if pageNum > 0 {
                pageNum -= 1
                viewDidLoad()
                viewDidAppear(true)
        }
        }
    }
    // 감시중인 key의 경로에 있는 값이 변경되면 아래함수 실행됨 - > "duration" player의 시간초가 바뀌면 감지
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.lbl_EndTime.text = getTimeString(player.currentItem!.duration)
            sl_VideoTime.maximumValue = Float(duration)
            cnt = 0 // 값이변경후 비디오상태라벨 등장 -> 값이 변경될때마다 시간을 초기화하여 중간에 사라지는걸 방지
            print("observer_activity \(player.currentTime().seconds)")
        }
    }
    
    
}
