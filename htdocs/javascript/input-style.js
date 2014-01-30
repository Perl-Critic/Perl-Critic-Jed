// Prevents Google Toolbar from coloring inputs yellow

if(window.attachEvent)
window.attachEvent("onload",setListeners);

function setListeners(){
inputList = document.getElementsByTagName("INPUT");
for(i=0;i<inputList.length;i++)
inputList[i].attachEvent("onpropertychange",restoreStyles);
selectList = document.getElementsByTagName("SELECT");
for(i=0;i<selectList.length;i++)
selectList[i].attachEvent("onpropertychange",restoreStyles);
}

function restoreStyles(){
if(event.srcElement.style.backgroundColor != "")
event.srcElement.style.backgroundColor = "";
}