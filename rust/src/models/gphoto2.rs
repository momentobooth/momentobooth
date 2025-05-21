use gphoto2::widget::Widget;

// Widget types that exist in the gphoto2 rust lib
// GroupWidget
// TextWidget
// RangeWidget
// ToggleWidget
// RadioWidget
// ButtonWidget
// DateWidget

/// Enum to represent different types of simplified widgets.
#[derive(Debug, Clone)]
pub enum SimplifiedWidgetType {
    /// A container for other widgets (maps to gphoto2 GroupWidget).
    Group,
    /// A text input or display (maps to gphoto2 TextWidget).
    Text,
    /// A numerical range slider (maps to gphoto2 RangeWidget).
    Range,
    /// A simple on/off switch (maps to gphoto2 ToggleWidget).
    Toggle,
    /// A set of exclusive choices (maps to gphoto2 RadioWidget).
    Radio,
    /// A button you can press (maps to gphoto2 ButtonWidget).
    Button,
    /// A date/time input (maps to gphoto2 DateWidget).
    Date,
    /// For any other widget types not explicitly handled.
    Unknown,
}

/// Represents a single simplified widget in your API's data structure.
#[derive(Debug, Clone)]
pub struct SimplifiedWidget {
    pub name: String,
    pub label: String,
    pub widget_type: SimplifiedWidgetType,
    pub readonly: bool,
    pub value: Option<SimplifiedValue>,
    pub choices: Option<Vec<String>>,
    pub range: Option<(f64, f64, f64)>, // min, max, step
    pub children: Vec<SimplifiedWidget>,
}

/// Enum to represent different types of widget values.
#[derive(Debug, Clone, PartialEq)]
pub enum SimplifiedValue {
    String(String),
    Integer(i64),
    Float(f64),
    Toggle(bool), // For ToggleWidget, true if on, false if off
    // Date could be represented as a String or a more specific type if needed
}

/// Converts a gphoto2 widget tree to a simplified nested data structure.
///
/// # Arguments
///
/// * `gphoto_widget`: A reference to the gphoto2 `Widget` to convert.
///
/// # Returns
///
/// An `Option<SimplifiedWidget>` containing the converted widget, or `None` if
/// the widget type is not directly convertible at the top level (e.g., internal nodes
/// that are not `SectionWidget` or `WindowWidget` if you only want those at the root).
/// This function is designed to be called recursively, building up the tree.
pub fn convert_gphoto_config(gphoto_widget: &Widget) -> Option<SimplifiedWidget> {
    let name = gphoto_widget.name();
    let label = gphoto_widget.label();
    let readonly = gphoto_widget.readonly();

    let mut children: Vec<SimplifiedWidget> = Vec::new();

    // Recursively convert children if it's a "group" type widget
    if let Widget::Group(group) = gphoto_widget {
        for child in group.children_iter() {
            if let Some(converted_child) = convert_gphoto_config(&child) {
                children.push(converted_child);
            }
        }
    }


    let (simplified_type, value, choices, range) = match gphoto_widget {
        Widget::Group(group) => (SimplifiedWidgetType::Group, None, None, None),
        Widget::Text(text) => {
            let val = SimplifiedValue::String(text.value());
            (SimplifiedWidgetType::Text, Some(val), None, None)
        }
        Widget::Range(range) => {
            let val = SimplifiedValue::Float(range.value().into());
            let (range, step) = range.range_and_step();
            let r = (range.start().clone() as f64, range.end().clone() as f64, step as f64);
            (SimplifiedWidgetType::Range, Some(val), None, Some(r))
        }
        Widget::Toggle(toggle) => {
            let val = toggle.toggled().map(|v| SimplifiedValue::Toggle(v));
            (SimplifiedWidgetType::Toggle, val, None, None)
        }
        Widget::Radio(radio) => {
            let val = SimplifiedValue::String(radio.choice());
            let ch: Vec<String> = radio.choices_iter().collect();
            (SimplifiedWidgetType::Radio, Some(val), Some(ch), None)
        }
        Widget::Button(button) => {
            (SimplifiedWidgetType::Button, None, None, None)
        }
        Widget::Date(date) => {
            // gphoto2 date is typically an epoch i64, convert to string or keep as int
            let val = SimplifiedValue::Integer(date.timestamp().into());
            (SimplifiedWidgetType::Date, Some(val), None, None)
        }
        _ => (SimplifiedWidgetType::Unknown, None, None, None),
    };

    Some(SimplifiedWidget {
        name,
        label,
        widget_type: simplified_type,
        readonly,
        value,
        choices,
        range,
        children,
    })
}