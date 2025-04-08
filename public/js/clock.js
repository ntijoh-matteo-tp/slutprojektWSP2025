const default_timers = document.getElementsByClassName('defaultTimerItem');

var localClock = document.getElementById('localClock');
var skyClock = document.getElementById('skyClock');

window.onload = UpdateClock();
function UpdateClock(){
    skyClockValueNew = (new Date().toLocaleTimeString('en-US', { timeZone: 'America/Los_Angeles', hour12: false }))
    localClockValueNew = (new Date().toLocaleTimeString())

    localClock.textContent = localClockValueNew
    skyClock.textContent = skyClockValueNew
    setTimeout(UpdateClock, 1000)
    for(let i = 0; i < default_timers.length ; i++){
        console.log(default_timers[i])
        CheckTimer(default_timers[i], skyClockValueNew)

        var container = document.getElementsByClassName("defaultTimerItem");
        var content = container.innerHTML;
        container = content; 
    }
}

function CheckTimer(timer, currentTime){
    //timerHour = timer.
    timerTime = timer.innerText.split("\n")[1]
    timerTimeHour = parseInt(timerTime.split(" : ")[0])
    timerTimeMinute = parseInt(timerTime.split(" : ")[1])

    currentTimeHour = parseInt(currentTime.split(":")[0])
    currentTimeMinute = parseInt(currentTime.split(":")[1])
    currentTimeSecond = parseInt(currentTime.split(" : ")[2])

    console.log("Timer minute is " + timerTimeMinute + " and current minute is " + currentTimeMinute)

    //currentTimeHour % 2 == 0
    if (currentTimeMinute == (timerTimeMinute) && currentTimeHour % 2 == 0 && currentTimeSecond == 0) {
        console.log("yo");
        window.alert("its time!!");
    }

    if (currentTimeMinute == (timerTimeMinute) && currentTimeHour % 2 == 0 && currentTimeSecond == 0) {
        console.log("yo");
        window.alert("its time!!");
    }
}