require 'application_system_test_case'

class ConversationsTest < ApplicationSystemTestCase
  test 'starting a conversation' do
    user = User.first
    login_as(user, scope: :user)

    to_user = User.second
    visit new_user_conversation_url(user, locale: :en)
    fill_in 'User', with: "https://greasyfork.org/users/#{to_user.id}"
    fill_in 'Message', with: '1 2 3 4'
    assert_difference -> { Conversation.count } => 1, -> { Message.count } => 1 do
      click_on 'Create conversation'
      assert_content "Conversation with #{to_user.name}"
    end

    assert_equal [user, to_user].sort, Conversation.last.users

    fill_in 'Message', with: '5 6 7 8'
    assert_difference -> { Conversation.count } => 0, -> { Message.count } => 1 do
      click_on 'Post reply'
      assert_content '5 6 7 8'
    end
  end

  test 'following conversation link when it already exists' do
    user = users(:geoff)
    login_as(user, scope: :user)

    to_user = users(:junior)
    visit user_url(to_user, locale: :en)
    click_on 'Send message'

    assert_content "Conversation with #{to_user.name}"
  end

  test 'starting a conversation when it already exists' do
    user = users(:geoff)
    login_as(user, scope: :user)

    to_user = users(:junior)
    visit new_user_conversation_url(user, locale: :en)
    fill_in 'User', with: "https://greasyfork.org/users/#{to_user.id}"

    fill_in 'Message', with: '1 2 3 4'
    assert_difference -> { Conversation.count } => 0, -> { Message.count } => 1 do
      click_on 'Create conversation'
      assert_content "Conversation with #{to_user.name}"
    end
  end

  test 'starting a conversation mentioning a user' do
    user = User.first
    login_as(user, scope: :user)

    to_user = User.second
    visit new_user_conversation_url(user, locale: :en)
    mentioned_user1 = users(:geoff)
    fill_in 'User', with: "https://greasyfork.org/users/#{to_user.id}"
    fill_in 'Message', with: 'Hey @Geoffrey'
    assert_difference -> { Conversation.count } => 1, -> { Message.count } => 1 do
      click_on 'Create conversation'
      assert_content "Conversation with #{to_user.name}"
    end
    assert_link '@Geoffrey', href: user_path(mentioned_user1, locale: :en)

    assert_equal [user, to_user].sort, Conversation.last.users

    mentioned_user2 = users(:consumer)
    fill_in 'Message', with: 'Hello @"Gordon J. Canada"'
    assert_difference -> { Conversation.count } => 0, -> { Message.count } => 1 do
      click_on 'Post reply'
      assert_link '@Gordon J. Canada', href: user_path(mentioned_user2, locale: :en)
    end
  end

  test 'failing validation posting a message' do
    user = users(:geoff)
    user.update!(preferred_markup: 'markdown')
    login_as(user, scope: :user)
    conversation = conversations(:geoff_and_junior)

    visit user_conversation_url(user, conversation, locale: :en)

    fill_in 'Message', with: 'a' * 100_001
    click_on 'Post reply'
    assert_content 'Message is too long'
  end

  test 'subscribing to a conversation' do
    user = users(:geoff)
    user.update!(preferred_markup: 'markdown')
    login_as(user, scope: :user)
    conversation = conversations(:geoff_and_junior)

    visit user_conversation_url(user, conversation, locale: :en)

    assert_difference -> { ConversationSubscription.count } => 1 do
      click_link 'Subscribe'
      assert_link 'Unsubscribe'
    end
    assert_difference -> { ConversationSubscription.count } => -1 do
      click_link 'Unsubscribe'
      assert_link 'Subscribe'
    end
  end
end
