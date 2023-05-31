import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';

function showToast(template, title, message, variant = 'success') {
  const event = new ShowToastEvent({
    title: title,
    message: message,
    variant: variant
  });
  template.dispatchEvent(event);
}

async function showAlert(label, errorMessage, theme = 'error' ) {
  await LightningAlert.open({
    message: errorMessage,
    theme: theme,
    label: label
  });

}

function isEmpty(val) {
  if (val === undefined)
    return true;

  if (typeof (val) == 'function' || typeof (val) == 'number' ||
    typeof (val) == 'boolean' || Object.prototype.toString.call(val) === '[object Date]')
    return false;

  if (val == null || val.length === 0)
    return true;

  if (typeof (val) == "object") {
    var r = true;

    for (var f in val)
      r = false;

    return r;
  }

  return false;
}

function isNumeric(str) {
  if (typeof str != "string") return false; 
  return !isNaN(str) && !isNaN(parseFloat(str));
}

function formatLabel(label, placeHolders) {
  for(var i = 0; i < placeHolders.length; i++) {
    var regexp = new RegExp('\\{' + i + '\\}', 'gi');
    label = label.replace(regexp, placeHolders[i]);
  }
  return label;
}

function arraysAreEqual(a, b) {
  return Array.isArray(a) &&
    Array.isArray(b) &&
    a.length === b.length &&
    a.every((val, index) => val === b[index]);
}

const delay = (ms = 1000) => new Promise(resolve => setTimeout(resolve, ms));
const minus = (a, b) => a.filter((x) => !b.includes(x));
const union = (a, b) => [...new Set([...a, ...b])];

export { showToast, showAlert, isEmpty, delay, minus, union, isNumeric, formatLabel, arraysAreEqual };