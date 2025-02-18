var localClock = document.getElementById('localClock');
var skyClock = document.getElementById('skyClock');

window.onload = UpdateClock();
function UpdateClock(){
    localClock.textContent = (new Date().toLocaleTimeString())
    skyClock.textContent = (new Date().toLocaleTimeString('en-US', { timeZone: 'America/Los_Angeles', hour12: false }))
    setTimeout(UpdateClock, 1000)
}