
Feature: User

  Background:
    Given pages:
      | title         | url           |
      | Content       | /user         |
      | Users         | /admin/people |
      | John          | /users/john   |
      | Katie         | /users/katie  |
    Given users:
      | name    | mail                | roles                |
      | John    | john@example.com    | site manager         |
      | Badmin  | admin@example.com   | site manager         |
      | Gabriel | gabriel@example.com | content creator      |
      | Jaz     | jaz@example.com     | editor               |
      | Katie   | katie@example.com   | content creator      |
      | Martin  | martin@example.com  | editor               |
      | Celeste | celeste@example.com | editor               |
    Given groups:
      | title    | author  | published |
      | Group 01 | Badmin  | Yes       |
      | Group 02 | Badmin  | Yes       |
      | Group 03 | Badmin  | No        |
    And group memberships:
      | user    | group    | role on group        | membership status |
      | Gabriel | Group 01 | administrator member | Active            |
      | Katie   | Group 01 | member               | Active            |
      | Jaz     | Group 01 | member               | Pending           |
      | Admin   | Group 02 | administrator member | Active            |
      | Celeste | Group 02 | member               | Active            |
    And "Tags" terms:
      | name    |
      | Health  |
      | Gov     |
    And datasets:
      | title      | publisher | author  | published        | tags     | description |
      | Dataset 01 | Group 01  | Katie   | Yes              | Health   | Test        |
      | Dataset 02 | Group 01  | Katie   | No               | Health   | Test        |
      | Dataset 03 | Group 01  | Gabriel | Yes              | Gov      | Test        |
      | Dataset 04 | Group 01  | Katie   | Yes              | Health   | Test        |

  @api @javascript
  Scenario: Edit own user account
    Given I am logged in as "Katie"
    And I am on "Katie" page
    When I follow "Edit"
    And I fill in "About" with "This is my profile"
    And I press "Save"
    Then I should see "The changes have been saved"
    Given I am an anonymous user
    When I am on "Katie" page
    And I click "About" in the "tabs" region
    Then I should see "This is my profile"

  @api @javascript
  Scenario: View the list of own published datasets on profile
    Given I am logged in as "Katie"
    And I am on "Katie" page
    Then I should see "2" items in the "content" region

  @api @fixme @testBug
    # TODO: Needs definition.
    #       This would take a long time to test manually, having to wait N minutes each time it's run.
    #       A possible solution to this would be to edit the cookies directly and speed up the waiting time
    #       that way. That would take time to figure out, would this test be worth the time?
  Scenario: User should be logged out automatically after N minutes
    Given I am on the homepage
