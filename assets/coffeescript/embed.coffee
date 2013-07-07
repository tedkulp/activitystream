EmbedListCtrl = ($scope, $http) ->
  $http
    method: 'get'
    url: '/stream/tedkulp?format=json'
    headers:
      'Content-Type': 'application/json'
  .success (data) ->
    $scope.events = data.events
