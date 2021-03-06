require './multi_order_by'
require './st_element_id'
require './st_shift_click'

ng = angular

angular.module('smart-table').directive 'stMultiSort', [
  'stConfig'
  '$parse'
  '$rootScope'
  'stUniqueId'
  'stShiftSort'
  (stConfig, $parse, $rootScope, stUniqueId, stShiftSort) ->
    restrict: 'A'
    require: '^stTable'
    link: (scope, element, attr, ctrl) ->
      predicate = attr.stMultiSort
      getter = $parse(predicate)
      index = 0
      classAscent = attr.stClassAscent or stConfig.sort.ascentClass
      classDescent = attr.stClassDescent or stConfig.sort.descentClass
      stateClasses = [
        classAscent
        classDescent
      ]
      sortDefault = undefined
      elementId = stUniqueId.generate()

      ###
      Use our custom orderBy filter, which supports reversing rows independently
      ###
      ctrl.setSortFunction 'multiOrderBy'

      ###
      Sort the rows.
      @param {Boolean} holdingShiftKey
      ###
      sort = (holdingShiftKey) ->
        index++
        tableState = ctrl.tableState()
        tableState.sort.predicate ?= []
        reverse = index % 2 is 0
        predicate = if ng.isFunction(getter(scope)) then getter(scope) else attr.stMultiSort

        do -> # clear existing sort
          indexOfExistingSort = do ->
            for i, sortConfig of ctrl.tableState().sort.predicate
              if sortConfig.elementId is elementId
                return i
            return -1
          if indexOfExistingSort isnt -1
            tableState.sort.predicate.splice indexOfExistingSort, 1

        do -> # add sort class to element
          index = if index % 2 == 0 then 2 else 1
          element.removeClass(stateClasses[index % 2]).addClass stateClasses[index - 1]
          if !holdingShiftKey
            $rootScope.$broadcast 'clearOtherSortClasses', elementId

        tableState.sort.predicate.splice stShiftSort.getIndex(elementId), 0,
          elementId: elementId
          predicate: predicate
          reverse: reverse == true

        tableState.pagination.start = 0
        ctrl.pipe()

      if attr.stSortDefault
        sortDefault = if scope.$eval(attr.stSortDefault)? then scope.$eval(attr.stSortDefault) else attr.stSortDefault

      if sortDefault
        index = if sortDefault == 'reverse' then 1 else 0
        sort()

      element.bind 'click', (e) ->
        return unless predicate
        if e.shiftKey
          stShiftSort.clickElement elementId
        else
          stShiftSort.clear()
        scope.$apply -> sort(e.shiftKey)

      scope.$on 'clearOtherSortClasses', (e, sortedElementId) ->
        if sortedElementId isnt elementId
          index = 0
          element.removeClass(classAscent).removeClass(classDescent)
]
