#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic

    page_sidebar(

      includeCSS("www/styles.css"),
      shinyjs::useShinyjs(),

      title = "Data Profiler",

      sidebar = sidebar(
        width = 350,

        h5("Import Data"),
        selectInput("dataset_select", "Choose Dataset", choices = names(datasets)),
        fileInput("upload", "Or Upload Your Own Dataset", accept = c(".csv", ".xlsx")),
        hr( class = "m-0"),
        mod_filter_ui("filter"),

        # Delete button; initially hidden
        actionButton("delete_upload", "Delete Dataset",
                     icon = icon("trash"), class = "btn-outline-danger")
      ),

      layout_columns(
        col_widths = c(9, 3),
        card(
          card_header( card_title("Data Preview") ),
          div( DTOutput("table") )
        ),
        card(
          card_header(card_title("File Information")),
          tableOutput("file_info")
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "dataProfileR"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
