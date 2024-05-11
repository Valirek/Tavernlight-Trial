// Runnable Example -- See below the commented section for implementation of function
/*
#include <memory>
#include <string>
#include <iostream>

using Inbox = uint16_t;
constexpr const uint16_t INDEX_WHEREVER = 1;
constexpr const uint16_t FLAG_NOLIMIT = 2;

constexpr const char *const NOT_LOADED_PLAYER{"notloaded"};
constexpr const char *const FAIL_LOGIN_PLAYER{"faillogin"};
constexpr const uint16_t FAIL_ITEM{99};

struct Player
{
    Player(void *, bool print = true) : _print(print)
    {
        if (_print)
            std::cout << "Player constructed" << std::endl;
    }
    ~Player()
    {
        if (_print)
            std::cout << "Player destructed" << std::endl;
    }
    Inbox getInbox() const { return 1; }
    bool isOffline() const { return true; }

    bool _print;
};

struct Item
{
    Item()
    {
        std::cout << "Item constructed" << std::endl;
    }
    ~Item()
    {
        std::cout << "Item destructed" << std::endl;
    }
    static Item* CreateItem(uint16_t id);
};

Item* Item::CreateItem(uint16_t id)
{
    if (id == FAIL_ITEM)
    {
        return nullptr;
    }
    return new Item{};
}

struct Game
{
    void addItemToPlayer(const std::string& recipient, uint16_t itemId);
    Player* getPlayerByName(const std::string& recipient) const 
    {
        // Non-owning return
        static Player player{nullptr, false};
        if (recipient == NOT_LOADED_PLAYER || recipient == FAIL_LOGIN_PLAYER)
        {
            return nullptr;
        }
        return &player;
    }
    void internalAddItem(Inbox, Item* item, uint16_t, uint16_t) 
    {
        // Takes ownership of item, so delete it here to free up memory for example
        delete item;
    }
};

namespace IOLoginData
{
bool loadPlayerByName(Player* player, const std::string& name)
{
    if (name == FAIL_LOGIN_PLAYER)
    {
        return false;
    }
    return true;
}
void savePLayer(Player *player) {}
}

Game g_game{};

int main()
{
    std::cout << "When player is not in game:" << std::endl;
    g_game.addItemToPlayer(NOT_LOADED_PLAYER, 1);
    std::cout << std::endl;

    std::cout << "When loading player from login data fails:" << std::endl;
    g_game.addItemToPlayer(FAIL_LOGIN_PLAYER, 1);
    std::cout << std::endl;

    std::cout << "When item creation fails:" << std::endl;
    g_game.addItemToPlayer("example", FAIL_ITEM);
    std::cout << std::endl;

    std::cout << "When player is in game and item creation succeeds" << std::endl;
    g_game.addItemToPlayer("example", 1);
    std::cout << std::endl;
}
// */


/**
 * The general idea behind my answer here is to use smart pointers to handle memory ownership. Even
 * though the game API is based on raw pointers, it can still be interfaced with well.
 * Using smart pointers also neatly points out exactly where taking and releasing ownership is occurring.
 */
void Game::addItemToPlayer(const std::string& recipient, uint16_t itemId)
{
    /**
     * This lambda is here to reduce duplication between the case where we have
     * a non-owning pointer and an owning pointer.
     */
    const auto addItem = [](Player* player, uint16_t itemId)
    {
        // I assume CreateItem gives ownership to the caller.
        // Using smart pointers here so that if item ever goes out of scope it is destroyed
        std::unique_ptr<Item> item{Item::CreateItem(itemId)};
        if (!item)
        {
            // This will free the memory due to the smart pointer.
            return;
        }

        /**
         * Following the question prompt I assume this function call works. In TFS it looks like this
         * function can fail. The failure case doesn't seem to cleanup item so this would have
         * to be changed to handle that.
         * 
         * I assume this call takes ownership of item. Since the API here is using raw pointers I call
         * release() so that the unique_ptr gives up its ownership but doesn't destroy the item.
         */
        g_game.internalAddItem(player->getInbox(), item.release(), INDEX_WHEREVER, FLAG_NOLIMIT);

        if (player->isOffline())
        {
            // I assume savePlayer does not take ownership of player. If it did we could just call release.
            IOLoginData::savePLayer(player);
        }
    };

    if (auto* const player{g_game.getPlayerByName(recipient)}; player)
    {
        // Simple case of a non-owning pointer, player doesn't get destroyed and doesn't need to.
        addItem(player, itemId);
        return;
    }

    if (auto player{std::make_unique<Player>(nullptr)}; 
        IOLoginData::loadPlayerByName(player.get(), recipient))
    {
        // The lambda allows us to call the exact same logic without it having to care if the raw pointer
        // is owned by us or not. Leaving this scope neatly destroys player without any manual deletes.
        addItem(player.get(), itemId);
        return;
    }

    /** 
     * A pattern is established above of: Try to load player, if successful add item and exit.
     * This pattern establishes an easy way to add any new player sources to this logic. Just add 
     * in the case and return if it succeeds.
     */
}