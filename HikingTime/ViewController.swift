//
//  ViewController.swift
//  HikingTime
//
//  Created by Ganger, Keith E on 4/3/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import UIKit
import iAd

class ViewController: UIViewController,UITextFieldDelegate, ADBannerViewDelegate {
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        distance.delegate = self
        elevation.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard"))
        tapGesture.cancelsTouchesInView = true
        scrollView.addGestureRecognizer(tapGesture)
        setDefaultPrefs()
        prefs.synchronize()
        self.canDisplayBannerAds = true
        banner.delegate = self
        
//        let rectangleAdView = ADBannerView(adType: ADAdType.MediumRectangle)
//        rectangleAdView?.delegate = self
    }
    
    func hideKeyboard(){
        elevation.resignFirstResponder();
        distance.resignFirstResponder();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBOutlet weak var banner: ADBannerView!

    @IBOutlet weak var scrollView: UIScrollView!
 
    @IBOutlet weak var tripType: UISegmentedControl!
    @IBOutlet weak var distance: UITextField!

    @IBOutlet weak var packWeight: UISegmentedControl!

    @IBOutlet weak var elevation: UITextField!
    @IBOutlet weak var distanceMetricToggle: UISegmentedControl!

    @IBOutlet weak var elevationMetricTogle: UISegmentedControl!
    
    @IBOutlet weak var breakSwitch: UISwitch!
    
    @IBOutlet weak var easyTerrain: UISlider!
    
    @IBOutlet weak var easyTerrainLabel: UILabel!
    
    @IBOutlet weak var moderateTerain: UISlider!
    @IBOutlet weak var moderateTerrainLabel: UILabel!
    
    @IBOutlet weak var difficultTerrain: UISlider!
    @IBOutlet weak var difficultTerrainLabel: UILabel!
    let prefs = NSUserDefaults.standardUserDefaults()
    
    enum SliderIndex: Int{
        case easy = 1
        case moderate = 2
        case difficult = 3


        static func getAllValues()->[SliderIndex]{
            return [.easy,.moderate,.difficult]
        }
        
        
    }
    
    
    @IBOutlet weak var fitnessFactor: UISegmentedControl!
    
    @IBOutlet weak var resultLabel: UILabel!

    
    func getSlider(tag:SliderIndex)->(label: UILabel,slider:UISlider){
        switch(tag){
        case .easy:
            return(easyTerrainLabel!,easyTerrain!)
        case .moderate:
            return(moderateTerrainLabel!,moderateTerain!)
        case .difficult:
            return(difficultTerrainLabel!,difficultTerrain!)
        }
        
    }
    func getOtherValues(index:SliderIndex) ->[SliderIndex]{
        let all = SliderIndex.getAllValues()
        return all.filter({$0 != index})
    }
    
    func calculateSliderTotal()->Float{
        var total : Float = 0.0
        for index in SliderIndex.getAllValues(){
          let slider = getSlider(index)
         total += slider.slider.value
        }
        return total
    }

 
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self.view.addSubview(banner)
        self.view.layoutIfNeeded()
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError
        error: NSError!) {
            banner.removeFromSuperview()
            self.view.layoutIfNeeded()
    }
    
  
    
    func setDefaultPrefs(){
        let defaults = [
            "ascent_rate_1":2.5,
            "ascent_rate_2":1.5,
            "ascent_rate_3":0.5,
            "feet_per_hour":2000,
            "descent_rate_1":3.0,
            "descent_rate_2":2.5,
            "descent_rate_3":0.5,
            "break_mins_per_hour":10,
            "summit_break":30,
            "pack_weight_factor":0.08,
        ]
        prefs.registerDefaults(defaults)
    }

    
    
    
  
    


    func getDistanceInMiles()->Float{
        var value :Float = 0.0;
        if distance.text != nil {
            let distanceString :NSString = distance.text!
          value=distanceString.floatValue
        }
        if distanceMetricToggle.selectedSegmentIndex == 1 {
            value = value * 0.621371
        }
        return value
        
    }
    @IBAction func updatePercents(sender: UISlider) {
        updateSlider(sender, value: sender.value)
        reduceOthersToFit(sender)
        performCalculation(sender)
        
    }
    
    func reduceOthersToFit(slider:UISlider){
        let myIndex = SliderIndex(rawValue: slider.tag)
        let others = getOtherValues(myIndex!)
        var currentTotal = calculateSliderTotal()
        var remainder = currentTotal-100
        for index in others {
            let slider = getSlider(index).slider
            let newVal = slider.value - remainder
            if newVal > 100 {
                remainder = 100 - slider.value
                updateSlider(slider, value: 100)
            }else if newVal < 0 {
                remainder = newVal
                updateSlider(slider, value: 100)
            }else{
                remainder = 0
                updateSlider(slider, value: newVal)
            }
        }
    }

    
    func updateSlider(slider: UISlider, value : Float){
       let percent = 5 * Int(round(value / 5))
        let labelText = "\(percent)%"
        let label = getSlider(SliderIndex(rawValue: slider.tag)!).label
        label.text=labelText
        slider.value = Float(percent)
    }
    
    func floatPref(key:String)->Float{
        let myString:NSString = prefs.stringForKey(key)!
        return myString.floatValue
    }
    
    func calcluateForTerrainType(terrainSliderIndex : SliderIndex) -> Float{
        let terrainPercent = getSlider(terrainSliderIndex).slider.value / 100;
        let assentRate = prefs.floatForKey("ascent_rate_\(terrainSliderIndex.rawValue)")
        let descentRate = prefs.floatForKey("descent_rate_\(terrainSliderIndex.rawValue)")
               let segmentMiles = getDistanceInMiles() * terrainPercent
        
        var time :Float = 0.0
        if tripType.selectedSegmentIndex == 0{
            time = segmentMiles /  assentRate
        }else if tripType.selectedSegmentIndex == 1{
            time = (segmentMiles / 2) / assentRate
            time += (segmentMiles / 2) / descentRate
        }else{
           time = segmentMiles / descentRate
        }
        return time
    
    }
 
    
    func getElevationInFeet()->Float{
        var value:Float = 0.0
        if(elevation.text != nil){
            let str :NSString = elevation.text!
            value = str.floatValue
        }
        if elevationMetricTogle.selectedSegmentIndex == 1{
            value = value * 3.28084
        }
        return value
    }
    
    @IBAction func performCalculation(sender: AnyObject) {
        let terrainTypes = SliderIndex.getAllValues()
        var totalTime :Float = 0
        for terrainType  in terrainTypes {
            totalTime += calcluateForTerrainType(terrainType)
        }
        
        
        if tripType.selectedSegmentIndex == 0 || tripType.selectedSegmentIndex == 1 {
            let feetPerHour = prefs.floatForKey("feet_per_hour")
            let elevationGain = getElevationInFeet()
            let elevationTime = elevationGain / feetPerHour
            totalTime += elevationTime
        }
        
        totalTime = adjustForFitness(totalTime)
        totalTime = adjustForPackweight(totalTime)
        totalTime = adjustForBreaks(totalTime)
        
        //rount to 10ths
        totalTime = roundToTenths(totalTime)
        
        resultLabel.text = "Hiking Time: \(totalTime) hours"
        resultLabel.hidden=false
        resultLabel.highlighted=true
        hideKeyboard()
        
        
    }
    
    func roundToTenths(value:Float)->Float{
        return Float (round(10 * value) / 10)
    }
    
    func adjustForPackweight(tripTime : Float) -> Float{
        let packWeightFactor = prefs.floatForKey("pack_weight_factor")
        let scalingFactor = Float(packWeight.selectedSegmentIndex) * 0.08
        return tripTime + tripTime * scalingFactor
    }
    
    func adjustForFitness(totalTime : Float)->Float{
        var adjustedTime:Float = totalTime
        let scalingFactor:Float = 0.15
        if fitnessFactor.selectedSegmentIndex == 0 {
            adjustedTime = totalTime * (1.0 + scalingFactor)
        }else if fitnessFactor.selectedSegmentIndex == 2{
            adjustedTime = totalTime * (1.0 - scalingFactor)
        }
       return adjustedTime
    }

    func adjustForBreaks(totalTime : Float)->Float{
        var adjustedTime : Float = totalTime
        let breakMinsPerHour = prefs.integerForKey("break_mins_per_hour")
        if breakSwitch.on {
            var breakTimeMins:Float =  Float((breakMinsPerHour * lroundf(totalTime - 1)))
            //factor in a summit break
            if(tripType.selectedSegmentIndex == 1){
                breakTimeMins += prefs.floatForKey("summit_break")
            }
            let breakTimeHours:Float = breakTimeMins / 60
            adjustedTime = totalTime + breakTimeHours
            
            
        }
        return adjustedTime
    }
    
    @IBAction func backgroundTap(sender: UIControl) {
        hideKeyboard()
    }
    
    func textFieldDidBeginEditing(textField: UITextField!) {    //delegate method
        
    }
    
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {
        if textField == distance {
            return (textField.text as NSString).floatValue > 0
 
        }else{
            return true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        return true
    }
    
    
    
    
}

