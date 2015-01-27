<?php
/**
 * @file
 * Additional setup tasks for DKAN.
 */

/**
 * Implements hook_install_tasks().
 */
function dkan_install_tasks() {
  $tasks = array();
  $tasks['dkan_additional_setup'] = array(
    'display_name' => 'Cleanup',
  );
  return $tasks;
}

/**
 * Implements hook_install_tasks_alter().
 */
function dkan_install_tasks_alter(&$tasks){
  $i = array_search('install_configure_form', array_keys($tasks));
  unset($tasks['install_configure_form']);

  $configure = array(
    'display_name' => 'Configure Site',
    'type' => 'form',
  );

  $t = array_merge(array_slice($tasks, 0, $i), array('dkan_configure_form' => $configure), array_slice($tasks, $i));
  $tasks = $t;
}


/**
 * Overrides install_configure_form core function.
 */
function dkan_configure_form($form, &$form_state, &$install_state){
  drupal_set_title(st('Configure site'));
  $settings_dir = conf_path();
  $settings_file = $settings_dir . '/settings.php';
  if (empty($_POST) && (!drupal_verify_install_file(DRUPAL_ROOT . '/' . $settings_file, FILE_EXIST | FILE_READABLE | FILE_NOT_WRITABLE) || !drupal_verify_install_file(DRUPAL_ROOT . '/' . $settings_dir, FILE_NOT_WRITABLE, 'dir'))) {
    drupal_set_message(st('All necessary changes to %dir and %file have been made, so you should remove write permissions to them now in order to avoid security risks. If you are unsure how to do so, consult the <a href="@handbook_url">online handbook</a>.', array('%dir' => $settings_dir, '%file' => $settings_file, '@handbook_url' => 'http://drupal.org/server-permissions')), 'warning');
  }
  drupal_add_js(drupal_get_path('module', 'system') . '/system.js');
  drupal_add_js('misc/timezone.js');
  drupal_add_js(array('copyFieldValue' => array('edit-site-mail' => array('edit-account-mail'))), 'setting');
  drupal_add_js('jQuery(function () { Drupal.cleanURLsInstallCheck(); });', 'inline');
  drupal_add_js('jQuery(function () { Drupal.hideEmailAdministratorCheckbox() });', 'inline');
  menu_rebuild();
  drupal_get_schema(NULL, TRUE);

  $f = _install_configure_form($form, $form_state, $install_state);

  $f['dkan_notifications'] = array(
    '#type' => 'fieldset',
    '#title' => st('DKAN notifications'),
    '#collapsible' => FALSE,
  );

  $f['dkan_notifications']['dkan_email_update'] = array(
    '#type' => 'checkboxes',
    '#options' => array(
      1 => st('Receive e-mail notifications about DKAN releases and enhancements'),
    ),
    '#default_value' => array(1, 2),
    '#description' => st('<a href="@drupal">NuCivic</a>. maintainer of DKAN, will send you emails about: <ul> <li> DKAN Releases </li> <li>Important security notifications</li> <li>DKAN feature updates and enhancements</li> </ul>', array('@drupal' => 'http://drupal.org')),
    '#weight' => 16,
  );

  return $f;
}

/**
 * Overrides install_configure_form_validate core function.
 */
function dkan_configure_form_validate($form, &$form_state){
  if ($error = user_validate_name($form_state['values']['account']['name'])) {
    form_error($form['admin_account']['account']['name'], $error);
  }
  if ($error = user_validate_mail($form_state['values']['account']['mail'])) {
    form_error($form['admin_account']['account']['mail'], $error);
  }
  if ($error = user_validate_mail($form_state['values']['site_mail'])) {
    form_error($form['site_information']['site_mail'], $error);
  }
}

/**
 * Overrides install_configure_form_submit core function.
 */
function dkan_configure_form_submit($form, &$form_state){
  global $user;

  variable_set('site_name', $form_state['values']['site_name']);
  variable_set('site_mail', $form_state['values']['site_mail']);
  variable_set('date_default_timezone', $form_state['values']['date_default_timezone']);
  variable_set('site_default_country', $form_state['values']['site_default_country']);
  variable_set('dkan_email_update', $form_state['values']['dkan_email_update'][1]);

  if ($form_state['values']['update_status_module'][1]) {
    module_enable(array('update'), FALSE);
    if ($form_state['values']['update_status_module'][2]) {
      variable_set('update_notify_emails', array($form_state['values']['account']['mail']));
    }
  }

  $account = user_load(1);
  $merge_data = array('init' => $form_state['values']['account']['mail'], 'roles' => !empty($account->roles) ? $account->roles : array(), 'status' => 1, 'timezone' => $form_state['values']['date_default_timezone']);
  user_save($account, array_merge($form_state['values']['account'], $merge_data));
  $user = user_load(1);
  user_login_finalize();

  if (isset($form_state['values']['clean_url'])) {
    variable_set('clean_url', $form_state['values']['clean_url']);
  }
  variable_set('install_time', $_SERVER['REQUEST_TIME']);
}

/**
 * Implements hook_requirements().
 */

function dkan_requirements($phase){
  $requirements = array();
  if ($phase == 'runtime') {
    if (!variable_get('dkan_email_update')) {
      $requirements['dkan_email_update'] = array(
        'title' => st('DKAN Notifications'),
        'value' => st('Disabled'),
        'severity' => REQUIREMENT_WARNING,
        'description' => st('You have not enabled DKAN notifications'),
        );
      }
  }
  return $requirements;
}

/**
 * Implements hook_install_tasks().
 */
function dkan_additional_setup() {
  // Change block titles for selected blocks.
  db_query("UPDATE {block} SET title ='<none>' WHERE delta = 'main-menu' OR delta = 'login'");
  variable_set('node_access_needs_rebuild', FALSE);
  variable_set('gravatar_size', 190);

  // Make sure markdown editor installs correctly.
  module_load_include('install', 'markdowneditor', 'markdowneditor');
  _markdowneditor_insert_latest();
  $data = array(
    'pages' => "node/*\ncomment/*\nsystem/ajax",
    'eid' => 5,
  );
  drupal_write_record('bueditor_editors', $data, array('eid'));

  dkan_default_content_base_install();
  // Keeps us from getting notices "No module defines permission".
  module_enable(array('dkan_sitewide_roles_perms'));

  features_revert(array('dkan_sitewide_menu' => array('content_menu_links')));
  features_revert(array('dkan_sitewide_menu' => array('menu_links')));
  features_revert(array('dkan_dataset_content_types' => array('field_base', 'field_instance')));
  features_revert(array('dkan_dataset_groups' => array('field_base')));
  features_revert(array('dkan_dataset_groups' => array('search_api_index')));
  features_revert(array('dkan_sitewide_search_db' => array('search_api_index')));
  cache_clear_all();
  features_revert(array('dkan_sitewide_search_db' => array('search_api_server')));
  features_revert(array('dkan_sitewide_roles_perms' => array('user_permission', 'og_features_permission')));
  unset($_SESSION['messages']['warning']);
  cache_clear_all();

}
