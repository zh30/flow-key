import XCTest
@testable import FlowKey

class KnowledgeBaseManagerTests: XCTestCase {
    
    var knowledgeManager: KnowledgeBaseManager!
    
    override func setUp() {
        super.setUp()
        knowledgeManager = KnowledgeBaseManager.shared
    }
    
    override func tearDown() {
        knowledgeManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialize() async {
        await knowledgeManager.initialize()
        
        // Test passes if no exception is thrown
        XCTAssertTrue(true)
    }
    
    // MARK: - Knowledge Item Management Tests
    
    func testAddKnowledgeItem() async {
        await knowledgeManager.initialize()
        
        do {
            let itemId = try await knowledgeManager.addKnowledgeItem(
                title: "Test Item",
                content: "This is a test knowledge item",
                type: .note,
                category: .personal,
                tags: ["test", "sample"]
            )
            
            XCTAssertFalse(itemId.isEmpty)
            
            // Verify item was added
            let item = knowledgeManager.getKnowledgeItem(id: itemId)
            XCTAssertNotNil(item)
            XCTAssertEqual(item?.title, "Test Item")
            XCTAssertEqual(item?.content, "This is a test knowledge item")
            XCTAssertEqual(item?.type, .note)
            XCTAssertEqual(item?.category, .personal)
            XCTAssertEqual(item?.tags, ["test", "sample"])
            
        } catch {
            XCTFail("Failed to add knowledge item: \(error)")
        }
    }
    
    func testUpdateKnowledgeItem() async {
        await knowledgeManager.initialize()
        
        do {
            // Add an item first
            let itemId = try await knowledgeManager.addKnowledgeItem(
                title: "Original Title",
                content: "Original content",
                type: .note,
                category: .personal
            )
            
            // Update the item
            try await knowledgeManager.updateKnowledgeItem(
                id: itemId,
                title: "Updated Title",
                content: "Updated content",
                category: .work,
                tags: ["updated"],
                isStarred: true
            )
            
            // Verify update
            let item = knowledgeManager.getKnowledgeItem(id: itemId)
            XCTAssertNotNil(item)
            XCTAssertEqual(item?.title, "Updated Title")
            XCTAssertEqual(item?.content, "Updated content")
            XCTAssertEqual(item?.category, .work)
            XCTAssertEqual(item?.tags, ["updated"])
            XCTAssertEqual(item?.isStarred, true)
            
        } catch {
            XCTFail("Failed to update knowledge item: \(error)")
        }
    }
    
    func testRemoveKnowledgeItem() async {
        await knowledgeManager.initialize()
        
        do {
            // Add an item first
            let itemId = try await knowledgeManager.addKnowledgeItem(
                title: "Test Item",
                content: "Test content",
                type: .note,
                category: .personal
            )
            
            // Verify item exists
            XCTAssertNotNil(knowledgeManager.getKnowledgeItem(id: itemId))
            
            // Remove the item
            try await knowledgeManager.removeKnowledgeItem(id: itemId)
            
            // Verify item was removed
            XCTAssertNil(knowledgeManager.getKnowledgeItem(id: itemId))
            
        } catch {
            XCTFail("Failed to remove knowledge item: \(error)")
        }
    }
    
    func testGetAllKnowledgeItems() async {
        await knowledgeManager.initialize()
        
        do {
            // Add multiple items
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 1",
                content: "Content 1",
                type: .note,
                category: .personal
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 2",
                content: "Content 2",
                type: .text,
                category: .work
            )
            
            let items = knowledgeManager.getAllKnowledgeItems()
            XCTAssertGreaterThanOrEqual(items.count, 2)
            
        } catch {
            XCTFail("Failed to get all knowledge items: \(error)")
        }
    }
    
    func testGetKnowledgeItemsByCategory() async {
        await knowledgeManager.initialize()
        
        do {
            // Add items to different categories
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Personal Item",
                content: "Personal content",
                type: .note,
                category: .personal
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Work Item",
                content: "Work content",
                type: .text,
                category: .work
            )
            
            let personalItems = knowledgeManager.getKnowledgeItems(by: .personal)
            let workItems = knowledgeManager.getKnowledgeItems(by: .work)
            
            XCTAssertGreaterThanOrEqual(personalItems.count, 1)
            XCTAssertGreaterThanOrEqual(workItems.count, 1)
            
            // Verify correct categorization
            XCTAssertTrue(personalItems.allSatisfy { $0.category == .personal })
            XCTAssertTrue(workItems.allSatisfy { $0.category == .work })
            
        } catch {
            XCTFail("Failed to get knowledge items by category: \(error)")
        }
    }
    
    func testGetKnowledgeItemsByType() async {
        await knowledgeManager.initialize()
        
        do {
            // Add items of different types
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Note Item",
                content: "Note content",
                type: .note,
                category: .personal
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Text Item",
                content: "Text content",
                type: .text,
                category: .work
            )
            
            let noteItems = knowledgeManager.getKnowledgeItems(by: .note)
            let textItems = knowledgeManager.getKnowledgeItems(by: .text)
            
            XCTAssertGreaterThanOrEqual(noteItems.count, 1)
            XCTAssertGreaterThanOrEqual(textItems.count, 1)
            
            // Verify correct typing
            XCTAssertTrue(noteItems.allSatisfy { $0.type == .note })
            XCTAssertTrue(textItems.allSatisfy { $0.type == .text })
            
        } catch {
            XCTFail("Failed to get knowledge items by type: \(error)")
        }
    }
    
    func testGetStarredKnowledgeItems() async {
        await knowledgeManager.initialize()
        
        do {
            // Add starred and non-starred items
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Starred Item",
                content: "Starred content",
                type: .note,
                category: .personal,
                tags: [],
                metadata: [:],
                isStarred: true
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Regular Item",
                content: "Regular content",
                type: .note,
                category: .personal,
                tags: [],
                metadata: [:],
                isStarred: false
            )
            
            let starredItems = knowledgeManager.getStarredKnowledgeItems()
            XCTAssertGreaterThanOrEqual(starredItems.count, 1)
            XCTAssertTrue(starredItems.allSatisfy { $0.isStarred })
            
        } catch {
            XCTFail("Failed to get starred knowledge items: \(error)")
        }
    }
    
    func testGetArchivedKnowledgeItems() async {
        await knowledgeManager.initialize()
        
        do {
            // Add archived and non-archived items
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Archived Item",
                content: "Archived content",
                type: .note,
                category: .personal,
                tags: [],
                metadata: [:],
                isArchived: true
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Active Item",
                content: "Active content",
                type: .note,
                category: .personal,
                tags: [],
                metadata: [:],
                isArchived: false
            )
            
            let archivedItems = knowledgeManager.getArchivedKnowledgeItems()
            XCTAssertGreaterThanOrEqual(archivedItems.count, 1)
            XCTAssertTrue(archivedItems.allSatisfy { $0.isArchived })
            
        } catch {
            XCTFail("Failed to get archived knowledge items: \(error)")
        }
    }
    
    // MARK: - Collection Management Tests
    
    func testCreateCollection() async {
        await knowledgeManager.initialize()
        
        do {
            let collectionId = try await knowledgeManager.createCollection(
                name: "Test Collection",
                description: "A test collection",
                category: .personal,
                tags: ["test"]
            )
            
            XCTAssertFalse(collectionId.isEmpty)
            
            // Verify collection was created
            let collection = knowledgeManager.getCollection(id: collectionId)
            XCTAssertNotNil(collection)
            XCTAssertEqual(collection?.name, "Test Collection")
            XCTAssertEqual(collection?.description, "A test collection")
            XCTAssertEqual(collection?.category, .personal)
            XCTAssertEqual(collection?.tags, ["test"])
            
        } catch {
            XCTFail("Failed to create collection: \(error)")
        }
    }
    
    func testUpdateCollection() async {
        await knowledgeManager.initialize()
        
        do {
            // Create a collection first
            let collectionId = try await knowledgeManager.createCollection(
                name: "Original Name",
                description: "Original description",
                category: .personal
            )
            
            // Update the collection
            try await knowledgeManager.updateCollection(
                id: collectionId,
                name: "Updated Name",
                description: "Updated description",
                category: .work,
                tags: ["updated"]
            )
            
            // Verify update
            let collection = knowledgeManager.getCollection(id: collectionId)
            XCTAssertNotNil(collection)
            XCTAssertEqual(collection?.name, "Updated Name")
            XCTAssertEqual(collection?.description, "Updated description")
            XCTAssertEqual(collection?.category, .work)
            XCTAssertEqual(collection?.tags, ["updated"])
            
        } catch {
            XCTFail("Failed to update collection: \(error)")
        }
    }
    
    func testRemoveCollection() async {
        await knowledgeManager.initialize()
        
        do {
            // Create a collection first
            let collectionId = try await knowledgeManager.createCollection(
                name: "Test Collection",
                description: "Test description"
            )
            
            // Verify collection exists
            XCTAssertNotNil(knowledgeManager.getCollection(id: collectionId))
            
            // Remove the collection
            try await knowledgeManager.removeCollection(id: collectionId)
            
            // Verify collection was removed
            XCTAssertNil(knowledgeManager.getCollection(id: collectionId))
            
        } catch {
            XCTFail("Failed to remove collection: \(error)")
        }
    }
    
    func testAddItemToCollection() async {
        await knowledgeManager.initialize()
        
        do {
            // Create a collection
            let collectionId = try await knowledgeManager.createCollection(
                name: "Test Collection",
                description: "Test description"
            )
            
            // Create a knowledge item
            let itemId = try await knowledgeManager.addKnowledgeItem(
                title: "Test Item",
                content: "Test content",
                type: .note,
                category: .personal
            )
            
            // Add item to collection
            try await knowledgeManager.addItemToCollection(itemId: itemId, collectionId: collectionId)
            
            // Verify item is in collection
            let itemsInCollection = knowledgeManager.getItemsInCollection(id: collectionId)
            XCTAssertEqual(itemsInCollection.count, 1)
            XCTAssertEqual(itemsInCollection.first?.id, itemId)
            
        } catch {
            XCTFail("Failed to add item to collection: \(error)")
        }
    }
    
    func testRemoveItemFromCollection() async {
        await knowledgeManager.initialize()
        
        do {
            // Create a collection
            let collectionId = try await knowledgeManager.createCollection(
                name: "Test Collection",
                description: "Test description"
            )
            
            // Create a knowledge item
            let itemId = try await knowledgeManager.addKnowledgeItem(
                title: "Test Item",
                content: "Test content",
                type: .note,
                category: .personal
            )
            
            // Add item to collection
            try await knowledgeManager.addItemToCollection(itemId: itemId, collectionId: collectionId)
            
            // Remove item from collection
            try await knowledgeManager.removeItemFromCollection(itemId: itemId, collectionId: collectionId)
            
            // Verify item is not in collection
            let itemsInCollection = knowledgeManager.getItemsInCollection(id: collectionId)
            XCTAssertEqual(itemsInCollection.count, 0)
            
        } catch {
            XCTFail("Failed to remove item from collection: \(error)")
        }
    }
    
    // MARK: - Search Tests
    
    func testSearchKnowledge() async {
        await knowledgeManager.initialize()
        
        do {
            // Add some knowledge items
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Swift Programming",
                content: "Swift is a powerful programming language",
                type: .code,
                category: .work,
                tags: ["swift", "programming"]
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "iOS Development",
                content: "iOS development with Swift",
                type: .text,
                category: .work,
                tags: ["ios", "swift"]
            )
            
            // Search for "Swift"
            let results = try await knowledgeManager.searchKnowledge(query: "Swift")
            XCTAssertGreaterThanOrEqual(results.count, 1)
            
            // Search with category filter
            let personalResults = try await knowledgeManager.searchKnowledge(
                query: "Swift",
                category: .personal
            )
            XCTAssertEqual(personalResults.count, 0)
            
            // Search with type filter
            let codeResults = try await knowledgeManager.searchKnowledge(
                query: "Swift",
                type: .code
            )
            XCTAssertGreaterThanOrEqual(codeResults.count, 1)
            
        } catch {
            XCTFail("Failed to search knowledge: \(error)")
        }
    }
    
    func testSearchByTags() async {
        await knowledgeManager.initialize()
        
        do {
            // Add items with specific tags
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 1",
                content: "Content 1",
                type: .note,
                category: .personal,
                tags: ["tag1", "common"]
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 2",
                content: "Content 2",
                type: .text,
                category: .work,
                tags: ["tag2", "common"]
            )
            
            // Search by tags
            let tag1Results = knowledgeManager.searchByTags(["tag1"])
            XCTAssertEqual(tag1Results.count, 1)
            XCTAssertEqual(tag1Results.first?.title, "Item 1")
            
            let commonResults = knowledgeManager.searchByTags(["common"])
            XCTAssertEqual(commonResults.count, 2)
            
        } catch {
            XCTFail("Failed to search by tags: \(error)")
        }
    }
    
    // MARK: - Statistics Tests
    
    func testGetKnowledgeStats() async {
        await knowledgeManager.initialize()
        
        do {
            // Add some knowledge items
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 1",
                content: "Content 1",
                type: .note,
                category: .personal,
                tags: ["tag1"]
            )
            
            let _ = try await knowledgeManager.addKnowledgeItem(
                title: "Item 2",
                content: "Content 2",
                type: .text,
                category: .work,
                tags: ["tag2"]
            )
            
            let stats = await knowledgeManager.getKnowledgeStats()
            
            XCTAssertGreaterThanOrEqual(stats.totalItems, 2)
            XCTAssertGreaterThanOrEqual(stats.itemsByCategory[.personal] ?? 0, 1)
            XCTAssertGreaterThanOrEqual(stats.itemsByCategory[.work] ?? 0, 1)
            XCTAssertGreaterThanOrEqual(stats.itemsByType[.note] ?? 0, 1)
            XCTAssertGreaterThanOrEqual(stats.itemsByType[.text] ?? 0, 1)
            XCTAssertGreaterThanOrEqual(stats.tags["tag1"] ?? 0, 1)
            XCTAssertGreaterThanOrEqual(stats.tags["tag2"] ?? 0, 1)
            
        } catch {
            XCTFail("Failed to get knowledge stats: \(error)")
        }
    }
    
    // MARK: - File Processing Tests
    
    func testProcessFile() async {
        await knowledgeManager.initialize()
        
        do {
            // Create a temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("test.txt")
            
            let testContent = """
            This is a test file.
            It contains multiple lines.
            And some sample text.
            """
            
            try testContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Process the file
            let itemId = try await knowledgeManager.processFile(fileURL)
            
            XCTAssertFalse(itemId.isEmpty)
            
            // Verify the item was created
            let item = knowledgeManager.getKnowledgeItem(id: itemId)
            XCTAssertNotNil(item)
            XCTAssertEqual(item?.title, "test")
            XCTAssertEqual(item?.content, testContent)
            XCTAssertEqual(item?.type, .text)
            
            // Clean up
            try FileManager.default.removeItem(at: fileURL)
            
        } catch {
            XCTFail("Failed to process file: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAddKnowledgeItemPerformance() async {
        await knowledgeManager.initialize()
        
        let startTime = Date()
        
        do {
            // Add multiple items
            for i in 0..<10 {
                _ = try await knowledgeManager.addKnowledgeItem(
                    title: "Item \(i)",
                    content: "Content for item \(i)",
                    type: .note,
                    category: .personal
                )
            }
            
            let endTime = Date()
            let processingTime = endTime.timeIntervalSince(startTime)
            
            XCTAssertLessThan(processingTime, 5.0) // Should complete within 5 seconds
            
        } catch {
            XCTFail("Failed performance test: \(error)")
        }
    }
    
    func testSearchPerformance() async {
        await knowledgeManager.initialize()
        
        do {
            // Add multiple items
            for i in 0..<20 {
                _ = try await knowledgeManager.addKnowledgeItem(
                    title: "Test Item \(i)",
                    content: "This is test content for item \(i)",
                    type: .note,
                    category: .personal
                )
            }
            
            let startTime = Date()
            
            // Perform search
            let results = try await knowledgeManager.searchKnowledge(query: "test")
            
            let endTime = Date()
            let processingTime = endTime.timeIntervalSince(startTime)
            
            XCTAssertGreaterThanOrEqual(results.count, 1)
            XCTAssertLessThan(processingTime, 2.0) // Should complete within 2 seconds
            
        } catch {
            XCTFail("Failed search performance test: \(error)")
        }
    }
}