$(document).ready(function() {
  add_inline_editing();
  $('#new_issue_resource').bind('submit', function() {
    $('input.button', $(this)).attr('disabled', true);
    return true;
  });
});

function add_inline_editing() {
  $('.resource_estimation_editable').each(function(element) {
    var $editable_element = $(this);
    var id = $editable_element.data('resource-id');
    var old_value = $editable_element.text();
    $editable_element.editable(function(value, settings) {
        var hours = parseInt(value);
        if (isNaN(hours)) {
          setTimeout(function() {
            alert("Failed to save resource: estimation is not a number.");
          }, 1);
          return(old_value);
        }
        if (hours <= 0) {
          setTimeout(function() {
            alert("Failed to save resource: estimation must be greater than 0.");
          }, 1);
          return(old_value);
        }
        if (!(parseFloat(value) === parseInt(value))) {
          setTimeout(function() {
            alert("Failed to save resource: estimation must be an integer.");
          }, 1);
          return(old_value);
        }
        $.ajax({
          url:'/issue_resources/'+ id,
          type:'PUT',
          data: {
            id: id,
            issue_resource: {
              estimation: value
            }
          },
          success: function(value) {
            old_value = value;
            var estimation = 0
            var fields = $('.estimation_cell .resource_estimation');
            fields.each(function(index) {
              estimation += parseInt($(this).text());
            });
            var hour_label = estimation < 2 ? 'hour' : 'hours';
            $('.issue-attributes td.estimated-hours').text(estimation+'.00 '+hour_label);
            $('#issue-form #issue_estimated_hours').val(estimation+'.0');
          },
          error: function(req) {
            alert("Error in request. Please try again later.");
          }
        });
        return hours;
      },
      {
        onblur: 'submit',
        tooltip: "Click to edit...",
        'event': 'editable',
      }
    );
    $('#cell-' + id).on('click', function() {
      $editable_element.trigger('editable');
      $('input', $editable_element).trigger('focus').trigger('select');
    })
  });
}
