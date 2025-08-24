#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic

  # Hide delete button initially
  shinyjs::hide("delete_upload")

  # Enable/disable dataset dropdown based on upload
  observeEvent(input$upload, {
    shinyjs::disable("dataset_select")
    shinyjs::show("delete_upload")
  })

  # Delete uploaded dataset (with confirmation modal)
  observeEvent(input$delete_upload, {

    showModal(modalDialog(
      title = "Confirm Delete",
      "Are you sure you want to delete the uploaded dataset?",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete", "Yes, Delete", class = "btn-danger")
      ),
      easyClose = TRUE
    ))
  })

  # Only delete when user confirms
  observeEvent(input$confirm_delete, {
    uploaded_data(NULL)          # Clear uploaded data
    shinyjs::reset("upload")              # Reset file input
    removeModal()                # Close modal
    shinyjs::hide("delete_upload")
    shinyjs::enable("dataset_select")
  })

  # Reactive dataset: either uploaded or selected
  uploaded_data <- reactiveVal(NULL)  # store uploaded dataset separately

  observeEvent(input$upload, {
    ext <- tools::file_ext(input$upload$name)
    df <- if (ext == "csv") {
      read.csv(input$upload$datapath, stringsAsFactors = FALSE)
    } else if (ext %in% c("xls", "xlsx")) {
      read_excel(input$upload$datapath)
    } else {
      validate("Invalid file type. Please upload CSV or Excel.")
    }
    uploaded_data(df)
  })

  # Delete uploaded dataset
  # observeEvent(input$delete_upload, {
  #   uploaded_data(NULL)
  #   # Clear the file input in UI
  #   shinyjs::reset("upload")
  # })

  # Dataset to use: uploaded or selected
  data <- reactive({
    if (!is.null(uploaded_data())) {
      uploaded_data()
    } else {
      req(input$dataset_select)
      datasets[[input$dataset_select]]
    }
  })

  # Pass dataset to dynamic filter module
  filtered_data <- mod_filter_server("filter", data)

  output$table <- renderDT({
    filtered_data() |>
      head(n = 20)
  })

  output$file_info <- renderTable({
    req(uploaded_data())
    info <- data.frame(
      c("Rows"),
      c(nrow(uploaded_data()) ),
      fix.empty.names = FALSE
    )
  })
}
