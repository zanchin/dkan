<?php
/**
 * @file
 * Additional setup tasks for DKAN.
 */

/**
 * Implements hook_install_tasks().
 */
function dkan_install_tasks() {
  return array(
    'dkan_additional_setup' => array(
        'display_name' => t('DKAN final setup tasks'),
        'display' => TRUE,
        'type' => 'batch',
        'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
    ),
  );
}

/**
 * DKAN setup task. Runs a series of helper functions defined below.
 */
function dkan_additional_setup() {
  return array(
      'operations' => array(
          array('dkan_theme_config', array()),
          array('dkan_change_block_titles', array()),
          array('dkan_install_markdown', array()),
          array('dkan_enable_roles_perms', array()),
          array('dkan_revert_feature', array('dkan_sitewide_menu', array('content_menu_links', 'menu_links'))),
          array('dkan_revert_feature', array('dkan_dataset_content_types', array('field_base', 'field_instance'))),
          array('dkan_revert_feature', array('dkan_dataset_groups', array('field_base'))),
          array('dkan_revert_feature', array('dkan_sitewide_roles_perms', array('user_permission', 'og_features_permission'))),
          array('dkan_revert_feature', array('dkan_sitewide', array('variable'))),
          array('dkan_revert_feature', array('dkan_data_story_storyteller_role', array('user_role', 'roles_permissions'))),
          array('dkan_revert_feature', array('dkan_sitewide_profile_page', array('menu_custom', 'menu_links'))),
          array('dkan_build_menu_links', array()),
          array('dkan_flush_image_styles', array()),
          array('dkan_colorizer_reset', array()),
          array('dkan_misc_variables_set', array()),
          array('dkan_set_adminrole', array()),
          array('dkan_topics_terms', array()),
      ),
  );
}

function dkan_theme_config(&$context) {
  $context['message'] = t('Setting theme options.');
  theme_enable(array('nuboot_radix'));
  theme_enable(array('seven'));
  variable_set('theme_default', 'nuboot_radix');
  variable_set('admin_theme', 'nuboot_radix');

  // Disable the default Bartik theme
  theme_disable(array('bartik'));
  theme_disable(array('seven'));
}

/**
 * Change block titles for selected blocks.
 */
function dkan_change_block_titles(&$context) {
  $context['message'] = t('Changing block titles for selected blocks');
  db_query("UPDATE {block} SET title ='<none>' WHERE delta = 'main-menu' OR delta = 'login'");
  variable_set('node_access_needs_rebuild', FALSE);
  variable_set('gravatar_size', 190);
}

/**
 * Make sure markdown editor installs correctly.
 * @param $context
 */
function dkan_install_markdown(&$context) {
  $context['message'] = t('Installing Markdown');
  module_load_include('install', 'markdowneditor', 'markdowneditor');
  _markdowneditor_insert_latest();
  $data = array(
      'pages' => "node/*\ncomment/*\nsystem/ajax",
      'eid' => 5,
  );
  drupal_write_record('bueditor_editors', $data, array('eid'));
}

/**
 * Keeps us from getting notices "No module defines permission".
 * @param $context
 */
function dkan_enable_roles_perms(&$context) {
  $context['message'] = t('Enabling Sitewide Roles and Permissions');
  module_enable(array('dkan_sitewide_roles_perms'));
}


/**
 * Revert particular feature components that have been overridden in the setup process
 *
 * @param $feature The feature module name
 * @param $components Array of components to revert
 * @param $context
 */
function dkan_revert_feature($feature, $components, &$context) {
  $context['message'] = t('Reverting feature %feature_name', array('%feature_name' => $feature));
  features_revert(array($feature => $components));
  cache_clear_all();
}

/**
 * Build menu links
 *
 * @param $context
 */
function dkan_build_menu_links(&$context) {
  $context['message'] = t('Building menu links');
  $menu_links = features_get_default('menu_links', 'dkan_sitewide_profile_page');
  menu_links_features_rebuild_ordered($menu_links, TRUE);
  unset($_SESSION['messages']['warning']);
  cache_clear_all();
}

/**
 * Flush the image styles
 *
 * @param $context
 */
function dkan_flush_image_styles(&$context) {
  $context['message'] = t('Flushing image styles');
  $menu_links = features_get_default('menu_links', 'dkan_sitewide_profile_page');
  menu_links_features_rebuild_ordered($menu_links, TRUE);
  unset($_SESSION['messages']['warning']);
  cache_clear_all();
  $image_styles = image_styles();
  foreach ( $image_styles as $image_style ) {
    image_style_flush($image_style);
  }
}

/**
 * Reset colorizer cache so that background colors and other colorizer settings are not blank at first page view
 *
 * @param $context
 */
function dkan_colorizer_reset(&$context) {
  $context['message'] = t('Resetting colorizer cache');
  global $theme_key;
  $instance = $theme_key;
  drupal_alter('colorizer_instance', $instance);
  $palette = colorizer_get_palette($theme_key, $instance);
  $file = colorizer_update_stylesheet($theme_key, $theme_key, $palette);
  clearstatcache();
  dkan_default_content_base_install();
}

/**
 * Set a number of miscellaneous variables
 *
 * @param $context
 */
function dkan_misc_variables_set(&$context) {
  $context['message'] = t('Setting misc DKAN variables');
  variable_set('honeypot_form_user_register_form', 1);
  variable_set('site_frontpage', 'welcome');
  variable_set('page_manager_node_view_disabled', FALSE);
  variable_set('page_manager_node_edit_disabled', FALSE);
  variable_set('page_manager_user_view_disabled', FALSE);
  // variable_set('page_manager_override_anyway', 'TRUE');
  variable_set('jquery_update_jquery_version', '1.7');
  // Disable selected views enabled by contributed modules.
  $views_disable = array(
      'og_extras_nodes' => TRUE,
      'feeds_log' => TRUE,
      'groups_page' => TRUE,
      'og_extras_groups' => TRUE,
      'og_extras_members' => TRUE,
      'dataset' => TRUE,
  );
  variable_set('views_defaults', $views_disable);
}

/**
 * Set the user admin role
 *
 * @param $context
 */
function dkan_set_adminrole(&$context) {
  $context['message'] = t('Setting user admin role');
  dkan_sitewide_roles_perms_set_admin_role();
}

/**
 * Adds new terms for the Topics taxonomy with images.
 *
 * And, returns [term].
 */
function dkan_topics_terms(&$context) {
  $vocab = taxonomy_vocabulary_machine_name_load('dkan_topics_term');
  $terms = taxonomy_term_load_multiple(array(), array('vid' => $vocab->vid));
  foreach ($terms as $term) {
    taxonomy_term_delete($term->tid);
  }

  $terms = [
    'Health', 'Hospital', 'Inpatient',
    'Medicare', 'State', 'National',
    'Quality', 'Community', 'Science',
    'Tech', 'Food', 'Weather',
  ];

  $return = array();
  foreach ($terms as $term) {
    $image = _dkan_topic_image($term);
    $term = (object) [
      'name' => $term,
      'vid' => $vocab->vid,
    ];

    $term->field_image = array();
    $term->field_image[LANGUAGE_NONE] = array();
    $term->field_image[LANGUAGE_NONE][0] = $image;
    $term->field_image[LANGUAGE_NONE][0]['alt'] = $term->name;
    taxonomy_term_save($term);
    $return[$term->name] = $term;
  }
  return $return;
}

/**
 * Copies term image and returns image definition array for the term.
 */
function _dkan_topic_image($term) {
  $path = drupal_get_path('profile', 'dkan');
  $filename = $term . '.png';
  $filepath = $path . '/images/topics/' . $filename;
  $filepath = drupal_realpath($filepath);
  $file = (object) [
    'uid' => 1,
    'uri' => $filepath,
    'filemime' => file_get_mimetype($filepath),
    'status' => 1,
  ];

  $destination  = 'public://';
  $destination_fix = 'public://styles/topic_medium/public';
  file_prepare_directory($destination, FILE_CREATE_DIRECTORY);
  file_prepare_directory($destination_fix, FILE_CREATE_DIRECTORY);

  file_copy($file, $destination . 'styles/topic_medium/public', FILE_EXISTS_REPLACE);
  $file = file_copy($file, $destination, FILE_EXISTS_REPLACE);
  return (array) $file;
}
