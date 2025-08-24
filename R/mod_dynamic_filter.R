# --- UI ---
mod_filter_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h5("Filters"),
    actionButton(ns("reset"), "Reset Filters", icon = icon("undo")),
    uiOutput(ns("filters"))
  )
}

# --- SERVER ---
mod_filter_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Store defaults for reset
    defaults <- reactiveVal(list())

    # Create dynamic UI grouped into an accordion
    output$filters <- renderUI({
      req(data())
      df <- data()

      numeric_filters <- list()
      categorical_filters <- list()
      date_filters <- list()
      default_values <- list()

      for (col in names(df)) {
        col_data <- df[[col]]
        input_id <- paste0("filter_", col)

        if (is.numeric(col_data)) {
          default_values[[input_id]] <- c(min(col_data, na.rm = TRUE), max(col_data, na.rm = TRUE))
          numeric_filters[[col]] <- sliderInput(
            ns(input_id), col,
            min = min(col_data, na.rm = TRUE),
            max = max(col_data, na.rm = TRUE),
            value = default_values[[input_id]]
          )

        } else if (inherits(col_data, "Date")) {
          default_values[[input_id]] <- c(min(col_data, na.rm = TRUE), max(col_data, na.rm = TRUE))
          date_filters[[col]] <- dateRangeInput(
            ns(input_id), col,
            start = default_values[[input_id]][1],
            end = default_values[[input_id]][2]
          )

        } else if (is.factor(col_data) || is.character(col_data)) {
          choices <- sort(unique(col_data))
          default_values[[input_id]] <- choices
          categorical_filters[[col]] <- shinyWidgets::pickerInput(
            ns(input_id), col,
            choices = choices,
            selected = choices,
            multiple = TRUE,
            options = shinyWidgets::pickerOptions(
              actionsBox = TRUE, liveSearch = TRUE
            )
          )
        }
      }

      # Save defaults (for reset)
      defaults(default_values)

      num_flag <- length(numeric_filters) > 0
      cat_flag <- length(categorical_filters) > 0
      dat_flag <- length(date_filters) > 0

      panels <- list(
        bslib::accordion_panel(
          "Numeric Filters",
          numeric_filters
        ),
        bslib::accordion_panel(
          "Categorical Filters",
          categorical_filters
        ),
        bslib::accordion_panel(
          "Date Filters",
          date_filters
        )
      )

      bslib::accordion(
        open = FALSE,
        if(num_flag) bslib::accordion_panel( "Numeric Filters", numeric_filters ),
        if(cat_flag) bslib::accordion_panel( "Categorical Filters", categorical_filters ),
        if(dat_flag) bslib::accordion_panel( "Date Filters", date_filters)
      )
      # tagList(
      #   tags$details(
      #     tags$summary("Numeric Filters"),
      #     tagList(numeric_filters)
      #   ),
      #   tags$details(
      #     tags$summary("Categorical Filters"),
      #     tagList(categorical_filters)
      #   ),
      #   tags$details(
      #     tags$summary("Date Filters"),
      #     tagList(date_filters)
      #   )
      # )
    })

    # Reset button
    observeEvent(input$reset, {
      req(defaults())
      for (id in names(defaults())) {
        updateInput <- paste0("update", class(defaults()[[id]])[1], "Input")
        # Handle each type manually
        if (is.numeric(defaults()[[id]])) {
          updateSliderInput(session, id, value = defaults()[[id]])
        } else if (inherits(defaults()[[id]], "Date")) {
          updateDateRangeInput(session, id, start = defaults()[[id]][1], end = defaults()[[id]][2])
        } else {
          shinyWidgets::updatePickerInput(session, id, selected = defaults()[[id]])
        }
      }
    })

    # Return filtered dataset
    filtered <- reactive({
      req(data())
      df <- data()

      for (col in names(df)) {
        col_data <- df[[col]]
        filter_id <- paste0("filter_", col)

        if (is.numeric(col_data)) {
          rng <- input[[filter_id]]
          if (!is.null(rng)) {
            df <- df[df[[col]] >= rng[1] & df[[col]] <= rng[2], ]
          }
        } else if (inherits(col_data, "Date")) {
          dr <- input[[filter_id]]
          if (!is.null(dr)) {
            df <- df[df[[col]] >= dr[1] & df[[col]] <= dr[2], ]
          }
        } else if (is.factor(col_data) || is.character(col_data)) {
          sel <- input[[filter_id]]
          if (!is.null(sel)) {
            df <- df[df[[col]] %in% sel, ]
          }
        }
      }
      df
    })

    return(filtered)
  })
}
