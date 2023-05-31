function dynamicSort(property) {
  var sortOrder = 1;

  if (property[0] === "-") {
    sortOrder = -1;
    property = property.substr(1);
  }

  return function (a, b) {
    if (sortOrder === -1) {
      return b[property].localeCompare(a[property]);
    } else {
      return a[property].localeCompare(b[property]);
    }
  }
}

function sortData(fieldName, filterData, sortAsc) {
  var dataToSort = (filterData);

  dataToSort = JSON.parse(JSON.stringify(dataToSort));
  dataToSort.sort(sortBy(fieldName, sortAsc));

  return dataToSort;
}

function sortBy(field, reverse, primer) {
  var key = primer ? function (x) { return primer(x[field]) } : function (x) { return x[field] };
  reverse = !reverse ? 1 : -1;
  return function (a, b) {
    return a = key(a),
      b = key(b),
      reverse * ((a > b) - (b > a));
  }
}

export { dynamicSort, sortData};